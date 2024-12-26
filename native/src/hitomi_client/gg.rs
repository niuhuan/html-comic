use serde_derive::{Deserialize, Serialize};

use crate::Result;

#[derive(Default, Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct GG {
    pub b: String,
    pub m_list: Vec<i64>,
    pub m_result: i64,
}

impl GG {
    pub(crate) fn s(&self, hash: &str) -> Result<i64> {
        let len = hash.len();
        let s = format!(
            "{}{}{}",
            &hash[len - 1..len],
            &hash[len - 3..len - 2],
            &hash[len - 2..len - 1]
        );
        Ok(i64::from_str_radix(&s, 16)?)
    }

    pub(crate) fn m(&self, s: i64) -> i64 {
        if self.m_list.contains(&s) {
            self.m_result
        } else if self.m_result == 0 {
            1
        } else {
            0
        }
    }
}
