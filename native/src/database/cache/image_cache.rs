use std::ops::Deref;

use sea_orm::entity::prelude::*;
use sea_orm::sea_query::Expr;
use sea_orm::EntityTrait;
use sea_orm::IntoActiveModel;
use sea_orm::QueryOrder;
use sea_orm::QuerySelect;

use crate::database::cache::CACHE_DATABASE;
use crate::database::{create_index, create_table_if_not_exists, index_exists};

#[derive(Clone, Debug, PartialEq, DeriveEntityModel)]
#[sea_orm(table_name = "image_cache")]
pub struct Model {
    #[sea_orm(primary_key, auto_increment = false)]
    pub image_key: String,
    pub useful: String,
    pub extends_field_int_first: Option<i32>,
    pub extends_field_int_second: Option<i32>,
    pub extends_field_int_third: Option<i32>,
    pub extends_field_int_fourth: Option<i32>,
    pub extends_field_int_fifth: Option<i32>,
    pub extends_field_string_first: Option<String>,
    pub extends_field_string_second: Option<String>,
    pub extends_field_string_third: Option<String>,
    pub extends_field_string_fourth: Option<String>,
    pub extends_field_string_fifth: Option<String>,
    pub local_path: String,
    pub cache_time: i64,
}

#[derive(Copy, Clone, Debug, EnumIter, DeriveRelation)]
pub enum Relation {}

impl ActiveModelBehavior for ActiveModel {}

pub(crate) async fn init() {
    let gdb = CACHE_DATABASE.get().unwrap().lock().await;
    let db = gdb.deref();
    create_table_if_not_exists(db, Entity).await;
    if !index_exists(db, "image_cache", "image_cache_idx_cache_time").await {
        create_index(
            db,
            "image_cache",
            vec!["cache_time"],
            "image_cache_idx_cache_time",
        )
        .await;
    }
}

pub(crate) async fn load_image_by_image_key(image_key: String) -> anyhow::Result<Option<Model>> {
    Ok(Entity::find_by_id(image_key)
        .one(CACHE_DATABASE.get().unwrap().lock().await.deref())
        .await?)
}

pub(crate) async fn load_images_by_image_keys(
    image_keys: Vec<String>,
) -> anyhow::Result<Vec<Model>> {
    Ok(Entity::find()
        .filter(Column::ImageKey.is_in(image_keys))
        .all(CACHE_DATABASE.get().unwrap().lock().await.deref())
        .await?)
}

pub(crate) async fn insert(model: Model) -> anyhow::Result<Model> {
    Ok(model
        .into_active_model()
        .insert(CACHE_DATABASE.get().unwrap().lock().await.deref())
        .await?)
}

pub(crate) async fn update_cache_time(image_key: String) -> anyhow::Result<()> {
    Entity::update_many()
        .col_expr(
            Column::CacheTime,
            Expr::value(chrono::Local::now().timestamp_millis()),
        )
        .filter(Column::ImageKey.eq(image_key))
        .exec(CACHE_DATABASE.get().unwrap().lock().await.deref())
        .await?;
    Ok(())
}

pub(crate) async fn take_100_cache(time: i64) -> anyhow::Result<Vec<Model>> {
    Ok(Entity::find()
        .filter(Column::CacheTime.lt(time))
        .order_by_asc(Column::CacheTime)
        .limit(100)
        .all(CACHE_DATABASE.get().unwrap().lock().await.deref())
        .await?)
}

pub(crate) async fn delete_by_image_key(image_key: String) -> anyhow::Result<()> {
    Entity::delete_many()
        .filter(Column::ImageKey.eq(image_key))
        .exec(CACHE_DATABASE.get().unwrap().lock().await.deref())
        .await?;
    Ok(())
}
