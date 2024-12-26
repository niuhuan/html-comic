use std::ops::Deref;

use sea_orm::entity::prelude::*;
use sea_orm::QueryOrder;
use sea_orm::QuerySelect;
use sea_orm::{EntityTrait, IntoActiveModel, Set};

use crate::database::active::ACTIVE_DATABASE;
use crate::database::{create_index, create_table_if_not_exists, index_exists};

#[derive(Clone, Debug, PartialEq, DeriveEntityModel)]
#[sea_orm(table_name = "comic_view_log")]
pub struct Model {
    #[sea_orm(primary_key, auto_increment = false)]
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

#[derive(Copy, Clone, Debug, EnumIter, DeriveRelation)]
pub enum Relation {}

impl ActiveModelBehavior for ActiveModel {}

pub(crate) async fn init() {
    let db = ACTIVE_DATABASE.get().unwrap().lock().await;
    create_table_if_not_exists(db.deref(), Entity).await;
    if !index_exists(db.deref(), "comic_view_log", "comic_view_log_idx_view_time").await {
        create_index(
            db.deref(),
            "comic_view_log",
            vec!["view_time"],
            "comic_view_log_idx_view_time",
        )
        .await;
    }
}

pub(crate) async fn view_info(mut model: Model) -> anyhow::Result<()> {
    let db = ACTIVE_DATABASE.get().unwrap().lock().await;
    if let Some(in_db) = Entity::find_by_id(model.comic_id.clone())
        .one(db.deref())
        .await?
    {
        let mut in_db = in_db.into_active_model();
        in_db.comic_id = Set(model.comic_id);
        in_db.comic_title = Set(model.comic_title);
        in_db.comic_artists = Set(model.comic_artists);
        in_db.comic_series = Set(model.comic_series);
        in_db.comic_tags = Set(model.comic_tags);
        in_db.comic_type = Set(model.comic_type);
        in_db.comic_img1 = Set(model.comic_img1);
        in_db.comic_img2 = Set(model.comic_img2);
        in_db.add_timestamp_utc = Set(model.add_timestamp_utc);
        in_db.view_time = Set(chrono::Local::now().timestamp_millis());
        in_db.update(db.deref()).await?;
    } else {
        model.view_time = chrono::Local::now().timestamp_millis();
        model.into_active_model().insert(db.deref()).await?;
    }
    Ok(())
}

pub(crate) async fn view_page(comic_id: i32, page_rank: i32) -> anyhow::Result<()> {
    let db = ACTIVE_DATABASE.get().unwrap().lock().await;
    if let Some(in_db) = Entity::find_by_id(comic_id).one(db.deref()).await? {
        let mut in_db = in_db.into_active_model();
        in_db.page_rank = Set(page_rank);
        in_db.view_time = Set(chrono::Local::now().timestamp_millis());
        in_db.update(db.deref()).await?;
    }
    Ok(())
}

pub(crate) async fn load_view_logs(page: i64) -> anyhow::Result<Vec<Model>> {
    let db = ACTIVE_DATABASE.get().unwrap().lock().await;
    Ok(Entity::find()
        .order_by_desc(Column::ViewTime)
        .offset(page as u64 * 20)
        .limit(20)
        .all(db.deref())
        .await?)
}

pub(crate) async fn view_log_by_comic_id(comic_id: i32) -> anyhow::Result<Option<Model>> {
    let db = ACTIVE_DATABASE.get().unwrap().lock().await;
    Ok(Entity::find_by_id(comic_id).one(db.deref()).await?)
}
