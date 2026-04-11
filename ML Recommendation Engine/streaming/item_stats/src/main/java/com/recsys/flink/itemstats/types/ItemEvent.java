package com.recsys.flink.itemstats.types;

import com.fasterxml.jackson.annotation.JsonProperty;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;

import java.io.Serializable;
import java.util.Map;

public class ItemEvent implements Serializable {

    private static final ObjectMapper MAPPER = new ObjectMapper();

    @JsonProperty("user_id")
    private String userId;

    @JsonProperty("item_id")
    private String itemId;

    @JsonProperty("event_type")
    private String eventType;

    @JsonProperty("timestamp_ms")
    private long timestampMs;

    @JsonProperty("metadata")
    private Map<String, Object> metadata;

    public ItemEvent() {}

    public ItemEvent(String userId, String itemId, String eventType, long timestampMs) {
        this.userId = userId;
        this.itemId = itemId;
        this.eventType = eventType;
        this.timestampMs = timestampMs;
    }

    public static ItemEvent fromJson(String json) throws JsonProcessingException {
        return MAPPER.readValue(json, ItemEvent.class);
    }

    public String toJson() throws JsonProcessingException {
        return MAPPER.writeValueAsString(this);
    }

    public String getUserId() { return userId; }
    public void setUserId(String userId) { this.userId = userId; }

    public String getItemId() { return itemId; }
    public void setItemId(String itemId) { this.itemId = itemId; }

    public String getEventType() { return eventType; }
    public void setEventType(String eventType) { this.eventType = eventType; }

    public long getTimestampMs() { return timestampMs; }
    public void setTimestampMs(long timestampMs) { this.timestampMs = timestampMs; }

    public Map<String, Object> getMetadata() { return metadata; }
    public void setMetadata(Map<String, Object> metadata) { this.metadata = metadata; }

    public static class ItemStats implements Serializable {
        private String itemId;
        private long windowEndMs;
        private int views;
        private int clicks;
        private int cartAdds;
        private int purchases;
        private long updatedAtMs;

        public ItemStats() {}

        public ItemStats(String itemId) {
            this.itemId = itemId;
            this.updatedAtMs = System.currentTimeMillis();
        }

        public void incrementView() { this.views++; }
        public void incrementClick() { this.clicks++; }
        public void incrementCartAdd() { this.cartAdds++; }
        public void incrementPurchase() { this.purchases++; }

        public double getCartRate() {
            return views > 0 ? (double) cartAdds / views : 0.0;
        }

        public double getConversionRate() {
            return clicks > 0 ? (double) purchases / clicks : 0.0;
        }

        public double computeSmoothedCtr(double priorClicks, double priorViews) {
            return (clicks + priorClicks) / (views + priorViews);
        }

        public Map<String, Object> toFeatureMap(String redisKeyPrefix, double priorClicks, double priorViews) {
            return Map.of(
                "item_id", itemId,
                "views_1h", views,
                "clicks_1h", clicks,
                "cart_adds_1h", cartAdds,
                "purchases_1h", purchases,
                "cart_rate_1h", getCartRate(),
                "conversion_rate_1h", getConversionRate(),
                "smoothed_ctr_1h", computeSmoothedCtr(priorClicks, priorViews),
                "_updated_at", updatedAtMs,
                "redis_key", redisKeyPrefix + itemId
            );
        }

        public String getItemId() { return itemId; }
        public void setItemId(String itemId) { this.itemId = itemId; }

        public long getWindowEndMs() { return windowEndMs; }
        public void setWindowEndMs(long windowEndMs) { this.windowEndMs = windowEndMs; }

        public int getViews() { return views; }
        public void setViews(int views) { this.views = views; }

        public int getClicks() { return clicks; }
        public void setClicks(int clicks) { this.clicks = clicks; }

        public int getCartAdds() { return cartAdds; }
        public void setCartAdds(int cartAdds) { this.cartAdds = cartAdds; }

        public int getPurchases() { return purchases; }
        public void setPurchases(int purchases) { this.purchases = purchases; }

        public long getUpdatedAtMs() { return updatedAtMs; }
        public void setUpdatedAtMs(long updatedAtMs) { this.updatedAtMs = updatedAtMs; }
    }
}