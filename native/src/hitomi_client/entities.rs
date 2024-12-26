use serde_derive::{Deserialize, Serialize};

macro_rules! enum_str {
    ($name:ident { $($variant:ident($str:expr), )* }) => {
        #[derive(Clone, Copy, Debug, Eq, PartialEq)]
        pub enum $name {
            $($variant,)*
        }

        impl $name {
            pub fn from_value(value: &str) -> anyhow::Result<Self> {
                match value {
                    $($str => Ok($name::$variant),)*
                    str => Err(anyhow::Error::msg(format!(
                        "unknown value({}) of {}",
                        str, stringify!($name),
                    ))),
                }
            }

            pub fn value(&self) -> &str {
                match *self {
                    $($name::$variant => $str,)*
                }
            }

            pub fn key(&self) -> &str {
                match *self {
                    $($name::$variant => stringify!($variant),)*
                }
            }
            pub fn from_key(key: &str) -> anyhow::Result<Self> {
                match key {
                    $(stringify!($variant) => Ok($name::$variant),)*
                    key => Err(anyhow::Error::msg(format!(
                        "unknown key({}) of {}",
                        key, stringify!($name),
                    ))),
                }
            }
        }

        impl std::fmt::Display for $name {
            fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
                match self {
                    $( $name::$variant => write!(f,"{}",$str), )*
                }
            }
        }

        impl ::serde::Serialize for $name {
            fn serialize<S>(&self, serializer: S) -> Result<S::Ok, S::Error>
                where S: ::serde::Serializer,
            {
                serializer.serialize_str(match *self {
                    $( $name::$variant => $str, )*
                })
            }
        }

        impl<'de> ::serde::Deserialize<'de> for $name {
            fn deserialize<D>(deserializer: D) -> Result<Self, D::Error>
                where D: ::serde::Deserializer<'de>,
            {
                struct Visitor;

                impl<'de> ::serde::de::Visitor<'de> for Visitor {
                    type Value = $name;

                    fn expecting(&self, formatter: &mut ::std::fmt::Formatter) -> ::std::fmt::Result {
                        write!(formatter, "a string for {}", stringify!($name))
                    }

                    fn visit_str<E>(self, value: &str) -> Result<$name, E>
                        where E: ::serde::de::Error,
                    {
                        match value {
                            $( $str => Ok($name::$variant), )*
                            _ => Err(E::invalid_value(::serde::de::Unexpected::Other(
                                &format!("unknown {} variant: {}", stringify!($name), value)
                            ), &self)),
                        }
                    }
                }
                deserializer.deserialize_str(Visitor)
            }
        }
    }
}

enum_str!(SortType{
    Index("index"),
    Popular("popular"),
    PopularToday("popular/today"),
    PopularWeek("popular/week"),
    PopularMonth("popular/month"),
    PopularYear("popular/year"),
});

enum_str!(ComicFilterType{
    Tag("tag"),
    Character("character"),
    Artist("artist"),
    Series("series"),
});

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ComicFilter {
    pub filter_type: ComicFilterType,
    pub filter_value: String,
}

enum_str!(Lang {
    All("all"),
    Id("indonesian"),
    Ca("catalan"),
    Ceb("cebuano"),
    Cs("czech"),
    Da("danish"),
    De("german"),
    Et("estonian"),
    En("english"),
    Es("spanish"),
    Eo("esperanto"),
    Fr("french"),
    It("italian"),
    La("latin"),
    Hu("hungarian"),
    Nl("dutch"),
    No("norwegian"),
    Pl("polish"),
    Btbr("portuguese"),
    Ro("romanian"),
    Sq("albanian"),
    Sk("slovak"),
    Fi("finnish"),
    Sv("swedish"),
    Tl("tagalog"),
    Vi("vietnamese"),
    Tr("turkish"),
    El("greek"),
    Mn("mongolian"),
    Ru("russian"),
    Uk("ukrainian"),
    He("hebrew"),
    Ar("arabic"),
    Fa("persian"),
    Th("thai"),
    Ko("korean"),
    Zh("chinese"),
    Ja("japanese"),
});

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ComicIdPage {
    pub records: Vec<i32>,
    pub min_index: i64,
    pub max_index: i64,
    pub limit: i64,
    pub offset: i64,
    pub total: i64,
}

#[derive(Default, Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct ComicIntroduction {
    pub comic_clazz: String,
    pub title: String,
    pub artist_list: Vec<String>,
    pub series: Vec<String>,
    pub comic_type: String,
    pub language: String,
    pub tags: Vec<String>,
    pub add_timestamp_utc: i64,
    pub img1: String,
    pub img2: String,
}

#[derive(Default, Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct ComicReaderInfo {
    #[serde(deserialize_with = "null_vec")]
    pub languages: Vec<Language>,
    #[serde(deserialize_with = "null_vec")]
    pub tags: Vec<Tag>,
    pub language_url: Option<String>,
    #[serde(deserialize_with = "null_vec")]
    pub files: Vec<ComicFile>,
    #[serde(deserialize_with = "null_vec")]
    pub artists: Vec<Artist>,
    pub videofilename: Option<String>,
    #[serde(deserialize_with = "null_vec")]
    pub scene_indexes: Vec<i64>,
    pub title: String,
    #[serde(deserialize_with = "null_vec")]
    pub related: Vec<i64>,
    #[serde(deserialize_with = "null_vec")]
    pub characters: Vec<Character>,
    pub date: String,
    #[serde(deserialize_with = "null_vec")]
    pub groups: Vec<Group>,
    pub video: Option<String>,
    #[serde(deserialize_with = "null_vec")]
    pub parodys: Vec<Parody>,
    pub language_localname: Option<String>,
    #[serde(rename = "type")]
    pub comic_type: String,
    pub japanese_title: Option<String>,
    pub language: Option<String>,
    pub id: String,
}

#[derive(Default, Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct Language {
    pub galleryid: String,
    pub name: String,
    pub url: String,
    pub language_localname: String,
}

#[derive(Default, Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct Tag {
    #[serde(default = "default_i32", deserialize_with = "fuzzy_i32")]
    pub male: i32,
    #[serde(default = "default_i32", deserialize_with = "fuzzy_i32")]
    pub female: i32,
    pub url: String,
    pub tag: String,
}

#[derive(Default, Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct ComicFile {
    pub name: String,
    pub width: i32,
    pub hasavif: i32,
    pub hash: String,
    pub haswebp: i32,
    pub height: i32,
}

#[derive(Default, Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct Artist {
    pub url: String,
    pub artist: String,
}

#[derive(Default, Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct Character {
    pub url: String,
    pub character: String,
}

#[derive(Default, Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct Group {
    pub group: String,
    pub url: String,
}

#[derive(Default, Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct Parody {
    pub parody: String,
    pub url: String,
}

fn null_vec<'de, D, T: for<'d> serde::Deserialize<'d>>(
    d: D,
) -> std::result::Result<Vec<T>, D::Error>
    where
        D: serde::Deserializer<'de>,
{
    let value: serde_json::Value = serde::Deserialize::deserialize(d)?;
    if value.is_null() {
        Ok(vec![])
    } else if value.is_array() {
        let mut vec: Vec<T> = vec![];
        for x in value.as_array().unwrap() {
            vec.push(match serde_json::from_value(x.clone()) {
                Ok(t) => t,
                Err(err) => return Err(serde::de::Error::custom(err.to_string())),
            });
        }
        Ok(vec)
    } else {
        Err(serde::de::Error::custom("type error"))
    }
}

fn fuzzy_i32<'de, D>(d: D) -> std::result::Result<i32, D::Error>
    where
        D: serde::Deserializer<'de>,
{
    let value: serde_json::Value = serde::Deserialize::deserialize(d)?;
    if value.is_i64() {
        Ok(value.as_i64().unwrap() as i32)
    } else if value.is_string() {
        let str = value.as_str().unwrap();
        if str.eq("") {
            return Ok(0);
        }
        let from: std::result::Result<i32, std::num::ParseIntError> =
            std::str::FromStr::from_str(str);
        match from {
            Ok(from) => Ok(from),
            Err(_) => Err(serde::de::Error::custom("parse error")),
        }
    } else {
        Err(serde::de::Error::custom("type error"))
    }
}

fn default_i32() -> i32 {
    0
}

#[derive(PartialEq)]
pub enum FileUrlOptimizationPriority {
    Avif,
    Webp,
}
