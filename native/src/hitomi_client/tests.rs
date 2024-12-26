use crate::Result;

use super::{Client, ComicFile, ComicFilter, ComicFilterType, Lang, SortType};

fn print<T>(result: Result<T>)
where
    T: serde::Serialize + Send + Sync,
{
    match result {
        Ok(t) => match serde_json::to_string(&t) {
            Ok(text) => println!("{}", text),
            Err(err) => panic!("{}", err),
        },
        Err(err) => panic!("{}", err),
    }
}

#[cfg(target_os = "windows")]
fn client() -> Client {
    crate::Client::new_with_agent(
        reqwest::ClientBuilder::new()
            .proxy(reqwest::Proxy::all("socks5://127.0.0.1:10808/").unwrap())
            .build()
            .unwrap(),
    )
}

#[tokio::test]
async fn test_comics() {
    print(
        client()
            .comics(
                ComicFilter {
                    filter_type: ComicFilterType::Tag,
                    filter_value: "full color".to_string(),
                },
                SortType::PopularWeek,
                Lang::Ja,
                0,
                10,
            )
            .await,
    );
    // {"records":[2202264,2202105,2202259,2202253,2202254,2202252,2202250,2202251,2202248,2202247],"min_index":0,"max_index":9,"limit":10,"offset":0,"total":705295}
}

#[tokio::test]
async fn test_comic_introduction() {
    print(client().comic_introduction(2202248).await);
}

#[tokio::test]
async fn test_comic_reader_info() {
    print(client().comic_reader_info(2202248).await);
}

const TEST_FILE: &str = r#"{"name":"4.jpg","width":1204,"hasavif":1,"hash":"b77ef8cdf4461a43f3a58acaffa95abd7aae805ce6a1b1d52479aeb14ed80d93","haswebp":1,"height":1700}"#;

#[tokio::test]
async fn test_file_url() {
    let client = client();
    let gg = client.download_gg().await.unwrap();
    let file: ComicFile = serde_json::from_str(TEST_FILE).unwrap();
    println!("{}", client.file_url(&gg, &file).unwrap());
    // web https://aa.hitomi.la/avif/1650877201/648/e474b251eda29035d7423b527b0e507034d7613b3dd3e7fb910c0f600f144882.avif
    //     https://ba.hitomi.la/avif/1650873602/985/b77ef8cdf4461a43f3a58acaffa95abd7aae805ce6a1b1d52479aeb14ed80d93.avif
    // 2202248
    // .header("Referer", "$BASE_URL/reader/$hlId.html")
    //  curl -x socks5://localhost:10808/ -H "Referer: https://hitomi.la/reader/2202248.html" https://ba.hitomi.la/webp/1650873602/648/e474b251eda29035d7423b527b0e507034d7613b3dd3e7fb910c0f600f144882.webp
}
