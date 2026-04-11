package com.recsys.flink.useremb.types;

import com.fasterxml.jackson.annotation.JsonProperty;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;

import java.io.Serializable;
import java.util.List;
import java.util.Map;

public class SessionUpdateEvent implements Serializable {

    private static final ObjectMapper MAPPER = new ObjectMapper();

    @JsonProperty("user_id")
    private String userId;

    @JsonProperty("features")
    private Map<String, Object> features;

    @JsonProperty("timestamp_ms")
    private long timestampMs;

    public SessionUpdateEvent() {}

    public static SessionUpdateEvent fromJson(String json) throws JsonProcessingException {
        return MAPPER.readValue(json, SessionUpdateEvent.class);
    }

    @SuppressWarnings("unchecked")
    public List<String> getLastViewedItems() {
        if (features == null) return List.of();
        Object viewed = features.get("last_viewed_items");
        if (viewed instanceof List) return (List<String>) viewed;
        return List.of();
    }

    @SuppressWarnings("unchecked")
    public List<String> getLastClickedItems() {
        if (features == null) return List.of();
        Object clicked = features.get("last_clicked_items");
        if (clicked instanceof List) return (List<String>) clicked;
        return List.of();
    }

    public String getUserId() { return userId; }
    public void setUserId(String userId) { this.userId = userId; }

    public Map<String, Object> getFeatures() { return features; }
    public void setFeatures(Map<String, Object> features) { this.features = features; }

    public long getTimestampMs() { return timestampMs; }
    public void setTimestampMs(long timestampMs) { this.timestampMs = timestampMs; }

    public static class UserEmbedding implements Serializable {
        private String userId;
        private float[] embedding;
        private long updatedAtMs;

        public UserEmbedding() {}

        public UserEmbedding(String userId, float[] embedding) {
            this.userId = userId;
            this.embedding = embedding;
            this.updatedAtMs = System.currentTimeMillis();
        }

        public String getUserId() { return userId; }
        public void setUserId(String userId) { this.userId = userId; }

        public float[] getEmbedding() { return embedding; }
        public void setEmbedding(float[] embedding) { this.embedding = embedding; }

        public long getUpdatedAtMs() { return updatedAtMs; }
        public void setUpdatedAtMs(long updatedAtMs) { this.updatedAtMs = updatedAtMs; }
    }
}