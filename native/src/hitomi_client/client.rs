use anyhow::Context;
use scraper::{Html, Selector};
use crate::hitomi_client::FileUrlOptimizationPriority;
use crate::hitomi_client::FileUrlOptimizationPriority::{Avif, Webp};

use crate::Result;

use super::{
    ComicFile, ComicFilter, ComicIdPage, ComicIntroduction, ComicReaderInfo, Lang, SortType,
};

const LTN_BASE_URL: &str = "https://ltn.hitomi.la";
const BASE_URL: &str = "https://hitomi.la";

pub struct Client {
    agent: reqwest::Client,
}

impl Client {
    pub fn new() -> Self {
        Self {
            agent: reqwest::ClientBuilder::new().build().unwrap(),
        }
    }

    pub fn new_with_agent(agent: reqwest::Client) -> Self {
        Self { agent }
    }

    pub async fn request_id_page(&self, url: &str, offset: i64, limit: i64) -> Result<ComicIdPage> {
        let response = self
            .agent
            .get(url)
            .header(
                "Range",
                format!("bytes={}-{}", offset * 4, (offset + limit) * 4 - 1), // 4byte of i32
            )
            .send()
            .await?
            .error_for_status()?;
        let range = response
            .headers()
            .get("Content-Range")
            .with_context(|| "range header error")?
            .to_str()?;
        let rege = regex::Regex::new(r"bytes (\d+)-(\d+)/(\d+)")?;
        if let Some(mat) = rege.captures(range) {
            let min = mat.get(1).unwrap().as_str().parse::<i64>()?;
            let max = mat.get(2).unwrap().as_str().parse::<i64>()?;
            let total = mat.get(3).unwrap().as_str().parse::<i64>()?;

            let min = min / 4;
            let max = (max - 3) / 4;
            let total = total / 4;

            let bytes = response.bytes().await?;
            if bytes.len() % 4 != 0 {
                return Err(anyhow::Error::msg("body len error"));
            }
            let records = bytes
                .chunks(4)
                .map(|ck| i32::from_be_bytes([ck[0], ck[1], ck[2], ck[3]]))
                .collect::<Vec<i32>>();
            Ok(ComicIdPage {
                records: records,
                min_index: min,
                max_index: max,
                limit,
                offset,
                total: total,
            })
        } else {
            return Err(anyhow::Error::msg("range header no match"));
        }
    }

    pub async fn comics(
        &self,
        comic_filter: impl Into<Option<ComicFilter>>,
        sort_type: SortType,
        lang: Lang,
        offset: i64,
        limit: i64,
    ) -> Result<ComicIdPage> {
        let url = match comic_filter.into() {
            None => format!("{}/{}-{}.nozomi", LTN_BASE_URL, sort_type, lang),
            Some(comic_filter) => format!(
                "{}/{}/{}/{}-{}.nozomi",
                LTN_BASE_URL, comic_filter.filter_type, sort_type, comic_filter.filter_value, lang
            ),
        };
        return self.request_id_page(&url, offset, limit).await;
    }

    pub async fn comic_introduction(&self, id: i32) -> Result<ComicIntroduction> {
        let body = self
            .agent
            .get(&format!("{}/galleryblock/{}.html", LTN_BASE_URL, id))
            .send()
            .await?
            .error_for_status()?
            .text()
            .await?;
        let fragment = Html::parse_fragment(&body);
        let mut series: Vec<String> = vec![];
        let mut comic_type: String = String::default();
        let mut language: String = String::default();
        let mut tags: Vec<String> = vec![];
        if let Some(item) = fragment
            .select(&Selector::parse("table.dj-desc").unwrap())
            .last()
        {
            let td_sec = Selector::parse("td").unwrap();
            let a_sec = Selector::parse("a").unwrap();
            for item in item.select(&Selector::parse("tr").unwrap()) {
                let mut tds = item.select(&td_sec);
                if let Some(title) = tds.next() {
                    if let Some(content) = tds.next() {
                        let title = title.inner_html();
                        match title.as_str() {
                            "Series" => {
                                for a in content.select(&a_sec) {
                                    series.push(a.inner_html())
                                }
                            }
                            "Type" => {
                                if let Some(a) = content.select(&a_sec).next() {
                                    comic_type = a.inner_html()
                                };
                            }
                            "Language" => {
                                if let Some(a) = content.select(&a_sec).next() {
                                    language = a.inner_html()
                                };
                            }
                            "Tags" => {
                                for a in content.select(&a_sec) {
                                    tags.push(a.inner_html())
                                }
                            }
                            _ => (),
                        }
                    }
                }
            }
        } else {
            return Err(anyhow::Error::msg("not found dj-content"));
        };
        let clazz = fragment
            .select(&Selector::parse("div").unwrap())
            .next()
            .with_context(|| "not found container div")?
            .value()
            .attr("class")
            .unwrap_or_default()
            .to_string();
        let (img1_sc, img2_sc) = if clazz.as_str() == "cg" {
            (
                Selector::parse(".cg-img1 img"),
                Selector::parse(".cg-img2 img"),
            )
        } else {
            (
                Selector::parse(".dj-img1 img"),
                Selector::parse(".dj-img2 img"),
            )
        };
        Ok(ComicIntroduction {
            comic_clazz: clazz,
            title: if let Some(item) = fragment
                .select(&Selector::parse("h1.lillie>a").unwrap())
                .last()
            {
                item.inner_html()
            } else {
                return Err(anyhow::Error::msg("not found title"));
            },
            artist_list: fragment
                .select(&Selector::parse("div.artist-list ul li a").unwrap())
                .into_iter()
                .map(|item| item.inner_html())
                .collect::<Vec<String>>(),
            series,
            comic_type,
            language,
            tags,
            add_timestamp_utc: if let Some(item) =
            fragment.select(&Selector::parse(".date").unwrap()).last()
            {
                chrono::DateTime::parse_from_str(
                    &format!("{}:00", item.inner_html()),
                    "%Y-%m-%d %H:%M:%S%z",
                )?
                    .naive_utc()
                    .timestamp()
            } else {
                return Err(anyhow::Error::msg("not found date"));
            },
            img1: if let Some(item) = fragment.select(&img1_sc.unwrap()).last() {
                format!(
                    "https:{}",
                    item.value().attr("data-src").unwrap_or_default()
                )
            } else {
                return Err(anyhow::Error::msg("not found img1"));
            },
            img2: if let Some(item) = fragment.select(&img2_sc.unwrap()).last() {
                format!(
                    "https:{}",
                    item.value().attr("data-src").unwrap_or_default()
                )
            } else {
                return Err(anyhow::Error::msg("not found img2"));
            },
        })
    }

    pub async fn comic_reader_info(&self, id: i32) -> Result<ComicReaderInfo> {
        let body = self
            .agent
            .get(&format!("{}/galleries/{}.js", LTN_BASE_URL, id))
            .send()
            .await?
            .error_for_status()?
            .text()
            .await?;
        let text = body.replace("var galleryinfo =", "");
        let info: ComicReaderInfo = from_str(&text)?;
        Ok(info)
    }

    pub async fn download_gg(&self) -> Result<super::gg::GG> {
        let body = self
            .agent
            .get(&format!("{}/gg.js", LTN_BASE_URL))
            .send()
            .await?
            .error_for_status()?
            .text()
            .await?;
        let mut m_list: Vec<i64> = vec![];
        let m_list_regex = regex::Regex::new(r"case (\d+):")?;
        for x in m_list_regex.captures_iter(body.as_str()) {
            m_list.push(x.get(1).unwrap().as_str().parse::<i64>().unwrap());
        }
        let m_result_regex = regex::Regex::new(r"o = (\d); break;")?;
        let m_result = m_result_regex
            .captures_iter(body.as_str())
            .next()
            .with_context(|| "m_result not found")?
            .get(1)
            .unwrap()
            .as_str()
            .parse::<i64>()
            .unwrap();
        let b_regex = regex::Regex::new(r"b: '([^']+)'")?;
        let b = b_regex
            .captures_iter(body.as_str())
            .next()
            .with_context(|| "m_result not found")?
            .get(1)
            .unwrap()
            .as_str()
            .to_string();
        Ok(super::gg::GG {
            m_list,
            m_result,
            b,
        })
    }

    pub fn file_url(&self, gg: &super::gg::GG, file: &ComicFile, op: Option<FileUrlOptimizationPriority>) -> Result<String> {
        let (ext, path, second_subdomain) = if file.hasavif == 1 && op == Some(Avif) {
            ("avif", "avif", "a")
        } else if file.haswebp == 1 && op == Some(Webp){
            ("webp", "webp", "a")
        } else {
            (
                file.name.split(".").last().with_context(|| "ext error")?,
                "images",
                "b",
            )
        };
        let s = gg.s(file.hash.as_str())?;
        let first_subdomain = if gg.m(s) == 1 { "b" } else { "a" };
        Ok(format!(
            "https://{}{}.hitomi.la/{}/{}{}/{}.{}",
            first_subdomain, second_subdomain, path, gg.b, s, file.hash, ext,
        ))
    }

    pub async fn download_image(&self, comic_id: i32, url: &str) -> Result<bytes::Bytes> {
        println!("URL: {}", url);
        println!("Referer: {}/reader/{}.html", BASE_URL, comic_id);
        Ok(self
            .agent
            .get(url)
            .header("Referer", format!("{}/reader/{}.html", BASE_URL, comic_id))
            .send()
            .await?
            .error_for_status()?
            .bytes()
            .await?)
    }
}

pub fn from_str<T: for<'de> serde::Deserialize<'de>>(json: &str) -> Result<T> {
    Ok(serde_path_to_error::deserialize(
        &mut serde_json::Deserializer::from_str(json),
    )?)
}
