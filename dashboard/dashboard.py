import streamlit as st
import pandas as pd
import plotly.express as px
from collections import Counter

# ✅ Dashboard setting
st.set_page_config(page_title="Taobao Behavior Dashboard", layout="wide")

# ✅ Load data and convert datetime
@st.cache_data
def load_data():
    df = pd.read_csv("data/user_behavior_sample.csv", header=None)
    df.columns = ["user_id", "item_id", "category_id", "behavior_type", "timestamp"]
    df["datetime"] = pd.to_datetime(df["timestamp"], unit="s")
    return df

df = load_data()

# ✅ Dashboard title
st.title("🛍️ Taobao User Behavior Dashboard")

# ✅ Sidebar Filters
st.sidebar.header("Filters")
# 强制限制在真实数据范围内：2017-11-25 到 2017-12-03
start_date = pd.to_datetime("2017-11-25").date()
end_date = pd.to_datetime("2017-12-03").date()
selected_date = st.sidebar.date_input("Date Range", [start_date, end_date],
                                      min_value=start_date, max_value=end_date)

behavior_types = st.sidebar.multiselect(
    "Behavior Types",
    df["behavior_type"].unique(),
    default=list(df["behavior_type"].unique())
)

# ✅ Filtering logic
if len(selected_date) == 2:
    df_filtered = df[
        (df["datetime"].dt.date >= selected_date[0]) &
        (df["datetime"].dt.date <= selected_date[1])
    ]
else:
    df_filtered = df.copy()

df_filtered = df_filtered[df_filtered["behavior_type"].isin(behavior_types)]
st.markdown(f"**Filtered Rows:** {len(df_filtered):,}")

# ✅ PV / UV Metrics
st.subheader("📊 PV & UV Overview")
pv = df_filtered[df_filtered["behavior_type"] == "pv"].shape[0]
uv = df_filtered["user_id"].nunique()

col1, col2 = st.columns(2)
col1.metric("Page Views (PV)", f"{pv:,}")
col2.metric("Unique Visitors (UV)", f"{uv:,}")

# ✅ Hourly Behavior Chart
st.subheader("⏰ Hourly Activity Distribution")
df_filtered["hour"] = df_filtered["datetime"].dt.hour
hourly_df = df_filtered.groupby(["hour", "behavior_type"]).size().reset_index(name="count")
fig_hour = px.bar(hourly_df, x="hour", y="count", color="behavior_type", title="Hourly Behavior Count")
st.plotly_chart(fig_hour, use_container_width=True)

# ✅ Conversion Funnel
st.subheader("🔁 Conversion Funnel (Sample)")
pivot = df_filtered.groupby("behavior_type").size()
funnel_df = pd.DataFrame({
    "Stage": ["View", "Favorite + Cart", "Purchase"],
    "Count": [
        pivot.get("pv", 0),
        pivot.get("fav", 0) + pivot.get("cart", 0),
        pivot.get("buy", 0)
    ]
})
fig_funnel = px.funnel(funnel_df, x="Count", y="Stage", title="Conversion Funnel")
st.plotly_chart(fig_funnel, use_container_width=True)

# ✅ Behavior Heatmap by Hour
st.subheader("🔥 User Behavior Heatmap by Hour")
heatmap_data = df_filtered.copy()
heatmap_data["hour"] = heatmap_data["datetime"].dt.hour
heatmap_matrix = heatmap_data.groupby(["behavior_type", "hour"]).size().reset_index(name="count")
heatmap_pivot = heatmap_matrix.pivot(index="behavior_type", columns="hour", values="count").fillna(0)
fig_heatmap = px.imshow(
    heatmap_pivot,
    labels=dict(x="Hour", y="Behavior Type", color="Count"),
    title="User Behavior Heatmap (Behavior Type vs. Hour)"
)
st.plotly_chart(fig_heatmap, use_container_width=True)

# ✅ Daily Visit Trend
st.subheader("📈 Daily Visit Trend (PV / UV)")
df_filtered["date"] = df_filtered["datetime"].dt.date
daily_pv = df_filtered[df_filtered["behavior_type"] == "pv"].groupby("date").size().reset_index(name="PV")
daily_uv = df_filtered.groupby("date")["user_id"].nunique().reset_index(name="UV")
daily_df = pd.merge(daily_pv, daily_uv, on="date", how="outer").fillna(0).sort_values("date")

fig_line = px.line(daily_df, x="date", y=["PV", "UV"], title="Daily Page Views and Unique Visitors", markers=True)
st.plotly_chart(fig_line, use_container_width=True)

# ✅ Repurchase Rate
st.subheader("🔁 Repurchase Rate")
purchase_df = df[df["behavior_type"] == "buy"]
user_buy_count = purchase_df.groupby("user_id").size()
repurchase_count = (user_buy_count > 1).sum()
total_buyers = user_buy_count.shape[0]
repurchase_rate = repurchase_count / total_buyers if total_buyers > 0 else 0.0

col3, col4 = st.columns(2)
col3.metric("Total Buyers", f"{total_buyers:,}")
col4.metric("Repurchase Rate", f"{repurchase_rate:.2%}")
