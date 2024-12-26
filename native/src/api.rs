use std::collections::HashMap;
use std::future::Future;
use std::path::Path;
use std::time::Duration;

use anyhow::{Context, Result};

use crate::database::active::comic_view_log;
use crate::database::cache::{image_cache, web_cache};
use crate::database::properties::property;
use crate::hitomi_client::{
    ComicFilter, ComicFilterType, ComicIdPage, ComicIntroduction, ComicReaderInfo, Lang, SortType,
};
use crate::utils::hash_lock;
use crate::{get_image_cache_dir, join_paths, CLIENT, RUNTIME};
use crate::hitomi_client::FileUrlOptimizationPriority::Webp;

pub fn init(root: String) {
    crate::init_root(&root);
}

fn block_on<T>(f: impl Future<Output=T>) -> T {
    RUNTIME.block_on(f)
}

pub fn desktop_root() -> Result<String> {
    #[cfg(target_os = "windows")]
    {
        Ok(join_paths(vec![
            std::env::current_exe()?
                .parent()
                .with_context(|| "error")?
                .to_str()
                .with_context(|| "error")?,
            "data",
        ]))
    }
    #[cfg(target_os = "macos")]
    {
        let home = std::env::var_os("HOME")
            .with_context(|| "error")?
            .to_str()
            .with_context(|| "error")?
            .to_string();
        Ok(join_paths(vec![
            home.as_str(),
            "Library",
            "Application Support",
            "niuhuan",
            "html",
        ]))
    }
    #[cfg(target_os = "linux")]
    {
        let home = std::env::var_os("HOME")
            .with_context(|| "error")?
            .to_str()
            .with_context(|| "error")?
            .to_string();
        Ok(join_paths(vec![home.as_str(), ".niuhuan", "html"]))
    }
    #[cfg(not(any(target_os = "linux", target_os = "windows", target_os = "macos")))]
    panic!("not supported")
}

pub fn set_proxy(url: String) -> Result<()> {
    block_on(async {
        let mut builder = reqwest::ClientBuilder::new()
            .user_agent("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.88 Safari/537.36")
            .timeout(Duration::from_secs(30));
        if url.as_str() != "" {
            builder = builder.proxy(reqwest::Proxy::all(url)?);
        }
        let client = crate::hitomi_client::Client::new_with_agent(builder.build()?);
        (*CLIENT.write().await) = client;
        Ok(())
    })
}

pub fn http_get(url: String) -> Result<String> {
    block_on(http_get_inner(url))
}

async fn http_get_inner(url: String) -> Result<String> {
    Ok(reqwest::ClientBuilder::new()
        .user_agent("html")
        .build()?
        .get(url)
        .send()
        .await?
        .error_for_status()?
        .text()
        .await?)
}

pub fn save_property(k: String, v: String) -> Result<()> {
    block_on(property::save_property(k, v))
}

pub fn load_property(k: String) -> Result<String> {
    block_on(property::load_property(k))
}

pub fn comics(
    comic_filter_type: Option<String>,
    comic_filter_value: Option<String>,
    sort_type: String,
    lang: String,
    offset: i64,
    limit: i64,
) -> Result<ComicIdPage> {
    let key = format!(
        "COMICS${}${}${}${}${}${}",
        match &comic_filter_type {
            None => "null",
            Some(value) => value,
        },
        match &comic_filter_value {
            None => "null",
            Some(value) => value,
        },
        sort_type,
        lang,
        offset,
        limit
    );
    let comic_filer = if let Some(comic_filter_type) = comic_filter_type {
        if let Some(comic_filter_value) = comic_filter_value {
            Some(ComicFilter {
                filter_type: ComicFilterType::from_value(comic_filter_type.as_str())?,
                filter_value: comic_filter_value,
            })
        } else {
            None
        }
    } else {
        None
    };
    let sort_type = SortType::from_value(sort_type.as_str())?;
    let lang = Lang::from_value(lang.as_str())?;
    block_on(web_cache::cache_first(
        key,
        Duration::from_secs(60 * 60 * 2),
        Box::pin(async move {
            CLIENT
                .read()
                .await
                .comics(comic_filer, sort_type, lang, offset, limit)
                .await
        }),
    ))
}

pub fn comic_introduction(id: i32) -> Result<ComicIntroduction> {
    let key = format!("COMIC_INTRODUCTION${}", id);
    block_on(async move {
        let comic_introduction: ComicIntroduction = web_cache::cache_first(
            key,
            Duration::from_secs(60 * 60 * 24 * 365 * 99),
            Box::pin(async move { CLIENT.read().await.comic_introduction(id).await }),
        )
            .await?;
        comic_view_log::view_info(comic_view_log::Model {
            comic_id: id,
            comic_title: comic_introduction.title.clone(),
            comic_artists: serde_json::to_string(&comic_introduction.artist_list)?,
            comic_series: serde_json::to_string(&comic_introduction.series)?,
            comic_tags: serde_json::to_string(&comic_introduction.tags)?,
            comic_type: comic_introduction.comic_type.clone(),
            comic_img1: comic_introduction.img1.clone(),
            comic_img2: comic_introduction.img2.clone(),
            add_timestamp_utc: comic_introduction.add_timestamp_utc,
            page_rank: 0,
            view_time: 0,
        })
            .await?;
        Ok(comic_introduction)
    })
}

pub fn comic_reader_info(id: i32) -> Result<ComicReaderInfo> {
    let key = format!("COMIC_READER_INFO${}", id);
    block_on(async move {
        web_cache::cache_first(
            key,
            Duration::from_secs(60 * 60 * 24 * 365 * 99),
            Box::pin(async move { CLIENT.read().await.comic_reader_info(id).await }),
        )
            .await
    })
}

pub struct ReaderInfoFile {
    pub comic_id: i32,
    pub name: String,
    pub hash: String,
    pub width: i32,
    pub height: i32,
    pub hasavif: i32,
    pub haswebp: i32,
    pub location_type: String,
    pub location: String,
}

pub fn comic_reader_info_files(
    comic_id: i32,
    files: Vec<crate::hitomi_client::ComicFile>,
) -> Result<Vec<ReaderInfoFile>> {
    block_on(async {
        // Files
        let mut kvs = Vec::<(String, crate::hitomi_client::ComicFile)>::new();
        for x in files {
            kvs.push((format!("{}|{}", comic_id, x.hash), x));
        }
        // in db
        let keys = kvs.iter().map(|kv| kv.0.clone()).collect::<Vec<String>>();
        let mut model_map = HashMap::<String, image_cache::Model>::new();
        for x in image_cache::load_images_by_image_keys(keys).await? {
            model_map.insert(x.image_key.clone(), x);
        }
        // gen urls
        let client = CLIENT.read().await;
        let mut vec: Vec<ReaderInfoFile> = vec![];
        let mut gg: Option<crate::hitomi_client::gg::GG> = None;
        for x in kvs {
            let (location_type, location) = if let Some(model) = model_map.get(&x.0) {
                ("path".to_string(), model.local_path.clone())
            } else {
                let gg = if let Some(gg) = &gg {
                    gg
                } else {
                    gg = Some(client.download_gg().await?);
                    gg.as_ref().unwrap()
                };
                ("url".to_string(), client.file_url(&gg, &x.1, Some(Webp))?)
            };
            vec.push(ReaderInfoFile {
                comic_id,
                name: x.1.name,
                hash: x.1.hash,
                width: x.1.width,
                height: x.1.height,
                hasavif: x.1.hasavif,
                haswebp: x.1.haswebp,
                location_type,
                location,
            });
        }
        Ok(vec)
    })
}

pub fn load_comic_introduction_img(comic_id: i32, scope: String, url: String) -> Result<String> {
    block_on(async {
        let _ = hash_lock(&url).await;
        if let Some(model) = image_cache::load_image_by_image_key(url.clone()).await? {
            image_cache::update_cache_time(url).await?;
            Ok(join_paths(vec![
                get_image_cache_dir().as_str(),
                model.local_path.as_str(),
            ]))
        } else {
            let local_path = hex::encode(md5::compute(&url).as_slice());
            let abs_path = join_paths(vec![get_image_cache_dir().as_str(), &local_path]);
            let bytes = CLIENT.read().await.download_image(comic_id, &url).await?;
            tokio::fs::write(&abs_path, &bytes).await?;
            let model = image_cache::Model {
                image_key: url,
                useful: "COMIC_INTRODUCTION".to_string(),
                extends_field_int_first: Some(comic_id),
                extends_field_int_second: None,
                extends_field_int_third: None,
                extends_field_int_fourth: None,
                extends_field_int_fifth: None,
                extends_field_string_first: Some(scope),
                extends_field_string_second: None,
                extends_field_string_third: None,
                extends_field_string_fourth: None,
                extends_field_string_fifth: None,
                local_path,
                cache_time: chrono::Local::now().timestamp_millis(),
            };
            let _ = image_cache::insert(model).await?;
            Ok(abs_path)
        }
    })
}

pub fn load_comic_image(file: ReaderInfoFile) -> Result<String> {
    // return local file
    if file.location_type.eq("path") {
        return Ok(join_paths(vec![
            get_image_cache_dir().as_str(),
            file.location.as_str(),
        ]));
    }
    // network also select db
    let image_key = format!("{}|{}", file.comic_id, file.hash);
    block_on(async {
        let _ = hash_lock(&image_key).await;
        if let Some(model) = image_cache::load_image_by_image_key(image_key.clone()).await? {
            image_cache::update_cache_time(image_key).await?;
            return Ok(join_paths(vec![
                get_image_cache_dir().as_str(),
                model.local_path.as_str(),
            ]));
        } else {
            let local_path = hex::encode(md5::compute(&image_key).as_slice());
            let abs_path = join_paths(vec![get_image_cache_dir().as_str(), &local_path]);
            let bytes = CLIENT
                .read()
                .await
                .download_image(file.comic_id, &file.location)
                .await?;
            tokio::fs::write(&abs_path, &bytes).await?;
            let model = image_cache::Model {
                image_key,
                useful: "COMIC_PAGE".to_string(),
                extends_field_int_first: Some(file.comic_id),
                extends_field_int_second: Some(file.width),
                extends_field_int_third: Some(file.height),
                extends_field_int_fourth: Some(file.hasavif),
                extends_field_int_fifth: Some(file.haswebp),
                extends_field_string_first: Some(file.name),
                extends_field_string_second: Some(file.hash),
                extends_field_string_third: None,
                extends_field_string_fourth: None,
                extends_field_string_fifth: None,
                local_path,
                cache_time: chrono::Local::now().timestamp_millis(),
            };
            let _ = image_cache::insert(model).await?;
            Ok(abs_path)
        }
    })
}

pub fn load_comic_view_logs(page: i64) -> Result<Vec<ComicViewLog>> {
    block_on(async {
        let db_logs = comic_view_log::load_view_logs(page).await?;
        Ok(db_logs
            .iter()
            .map(|d| map_comic_view_log(d.clone()))
            .collect())
    })
}

pub fn view_log_by_comic_id(comic_id: i32) -> Result<Option<ComicViewLog>> {
    block_on(async {
        Ok(
            match comic_view_log::view_log_by_comic_id(comic_id).await? {
                None => None,
                Some(res) => Some(map_comic_view_log(res)),
            },
        )
    })
}

pub fn comic_view_page(comic_id: i32, page_rank: i32) -> Result<()> {
    block_on(comic_view_log::view_page(comic_id, page_rank))
}

pub struct ComicViewLog {
    pub comic_id: i32,
    pub comic_title: String,
    pub comic_artists: String,
    pub comic_series: String,
    pub comic_tags: String,
    pub comic_type: String,
    pub comic_img1: String,
    pub comic_img2: String,
    pub add_timestamp_utc: i64,
    pub page_rank: i32,
    pub view_time: i64,
}

fn map_comic_view_log(model: comic_view_log::Model) -> ComicViewLog {
    ComicViewLog {
        comic_id: model.comic_id,
        comic_title: model.comic_title,
        comic_artists: model.comic_artists,
        comic_series: model.comic_series,
        comic_tags: model.comic_tags,
        comic_type: model.comic_type,
        comic_img1: model.comic_img1,
        comic_img2: model.comic_img2,
        add_timestamp_utc: model.add_timestamp_utc,
        page_rank: model.page_rank,
        view_time: model.view_time,
    }
}

pub fn auto_clean(time: i64) -> Result<()> {
    let dir = get_image_cache_dir();
    block_on(async {
        loop {
            let caches: Vec<image_cache::Model> = image_cache::take_100_cache(time.clone()).await?;
            if caches.is_empty() {
                break;
            }
            for cache in caches {
                let local = join_paths(vec![dir.as_str(), cache.local_path.as_str()]);
                image_cache::delete_by_image_key(cache.image_key).await?; // 不管有几条被作用
                let _ = std::fs::remove_file(local); // 不管成功与否
            }
        }
        web_cache::clean_web_cache_by_time(time).await?;
        crate::database::cache::vacuum().await?;
        Ok(())
    })
}

pub fn clean_all_cache() -> Result<()> {
    auto_clean(1)
}

pub fn copy_image_to(src_path: String, to_dir: String) -> Result<()> {
    let name = Path::new(&src_path)
        .file_name()
        .unwrap()
        .to_str()
        .unwrap()
        .to_owned();
    let ext = image::io::Reader::open(&src_path)?
        .with_guessed_format()?
        .format()
        .with_context(|| anyhow::Error::msg("img format error"))?
        .extensions_str()[0];
    let final_name = format!("{}.{}", name, ext);
    let target = join_paths(vec![to_dir.as_str(), final_name.as_str()]);
    std::fs::copy(src_path.as_str(), target.as_str())?;
    Ok(())
}
