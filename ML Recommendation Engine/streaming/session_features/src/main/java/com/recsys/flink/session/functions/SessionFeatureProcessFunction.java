package com.recsys.flink.session.functions;

import com.recsys.flink.session.SessionFeatureConfig;
import com.recsys.flink.session.types.UserEvent;
import org.apache.flink.api.common.state.ListState;
import org.apache.flink.api.common.state.ListStateDescriptor;
import org.apache.flink.api.common.state.ValueState;
import org.apache.flink.api.common.state.ValueStateDescriptor;
import org.apache.flink.api.common.typeinfo.TypeInformation;
import org.apache.flink.configuration.Configuration;
import org.apache.flink.streaming.api.functions.KeyedProcessFunction;
import org.apache.flink.util.Collector;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class SessionFeatureProcessFunction extends KeyedProcessFunction<String, UserEvent, UserEvent> {

    private static final Logger LOG = LoggerFactory.getLogger(SessionFeatureProcessFunction.class);

    private final SessionFeatureConfig config;

    private transient ValueState<SessionState> sessionState;
    private transient ListState<UserEvent> lateEvents;

    public SessionFeatureProcessFunction(SessionFeatureConfig config) {
        this.config = config;
    }

    @Override
    public void open(Configuration parameters) {
        sessionState = getRuntimeContext().getState(
                new ValueStateDescriptor<>("session-state", TypeInformation.of(SessionState.class))
        );

        lateEvents = getRuntimeContext().getListState(
                new ListStateDescriptor<>("late-events", TypeInformation.of(UserEvent.class))
        );
    }

    @Override
    public void processElement(UserEvent event, Context ctx, Collector<UserEvent> out) throws Exception {
        long currentWatermark = ctx.timerService().currentWatermark();
        long eventTimestamp = event.getTimestampMs();
        long latenessMs = currentWatermark - eventTimestamp;
        long latenessSeconds = latenessMs / 1000;

        if (latenessMs > config.getLateEventWatermarkMinutes() * 60 * 1000L) {
            if (latenessSeconds < config.getMaxLateEventWindowMinutes() * 60) {
                LOG.debug("Late event within window: {}s late, forwarding to late-event topic", latenessSeconds);
                lateEvents.add(event);
                ctx.output(LateEventFilterFunction.LATE_EVENT_TAG, event.toJson());
            } else {
                LOG.warn("Dropping extremely late event: {}s late for user {}", latenessSeconds, event.getUserId());
            }
            return;
        }

        SessionState state = sessionState.value();
        if (state == null) {
            state = new SessionState();
            state.setUserId(event.getUserId());
            state.setSessionId(event.getSessionId());
            state.setSessionStartMs(event.getTimestampMs());
        }

        state.setLastEventMs(event.getTimestampMs());

        String eventType = event.getEventType();
        if ("VIEW".equals(eventType)) {
            state.incViewCount();
            List<String> viewedItems = state.getViewedItems();
            String itemId = event.getItemId();
            if (itemId != null && !itemId.isEmpty() && !viewedItems.contains(itemId)) {
                viewedItems.add(itemId);
                if (viewedItems.size() > config.getMaxViewedItems()) {
                    viewedItems.remove(0);
                }
            }
            String category = (String) event.getMetadata().get("category");
            if (category != null) {
                state.getCategoryViews().merge(category, 1, Integer::sum);
            }

        } else if ("CLICK".equals(eventType)) {
            state.incClickCount();
            state.getClickedItems().add(event.getItemId());

        } else if ("ADD_TO_CART".equals(eventType)) {
            state.incCartAddCount();
            state.getCartItems().add(event.getItemId());

        } else if ("PURCHASE".equals(eventType)) {
            state.incPurchaseCount();

        } else if ("SEARCH".equals(eventType)) {
            String query = (String) event.getMetadata().get("query");
            if (query != null && !query.isEmpty()) {
                state.getSearchQueries().add(query);
                if (state.getSearchQueries().size() > config.getMaxSearchQueries()) {
                    state.getSearchQueries().remove(0);
                }
            }
        }

        if (state.getSessionStartMs() > 0 && state.getLastEventMs() > 0) {
            double gapSeconds = (event.getTimestampMs() - state.getLastEventMs()) / 1000.0;
            state.setTotalDwellTimeSec(state.getTotalDwellTimeSec() + Math.min(gapSeconds, 300));
        }

        sessionState.update(state);

        UserEvent outputEvent = new UserEvent.UserEvent.Builder()
                .userId(event.getUserId())
                .sessionId(event.getSessionId())
                .eventType("SESSION_UPDATE")
                .timestampMs(System.currentTimeMillis())
                .metadata("features", state.toFeatureMap())
                .build();

        out.collect(outputEvent);
    }

    public static class SessionState {
        private String userId;
        private String sessionId;
        private long sessionStartMs = 0;
        private long lastEventMs = 0;

        private int viewCount = 0;
        private int clickCount = 0;
        private int cartAddCount = 0;
        private int purchaseCount = 0;
        private double totalDwellTimeSec = 0.0;

        private List<String> viewedItems = new ArrayList<>();
        private List<String> clickedItems = new ArrayList<>();
        private List<String> cartItems = new ArrayList<>();
        private List<String> searchQueries = new ArrayList<>();

        private Map<String, Integer> categoryViews = new HashMap<>();

        public void incViewCount() { this.viewCount++; }
        public void incClickCount() { this.clickCount++; }
        public void incCartAddCount() { this.cartAddCount++; }
        public void incPurchaseCount() { this.purchaseCount++; }

        public String getUserId() { return userId; }
        public void setUserId(String userId) { this.userId = userId; }

        public String getSessionId() { return sessionId; }
        public void setSessionId(String sessionId) { this.sessionId = sessionId; }

        public long getSessionStartMs() { return sessionStartMs; }
        public void setSessionStartMs(long sessionStartMs) { this.sessionStartMs = sessionStartMs; }

        public long getLastEventMs() { return lastEventMs; }
        public void setLastEventMs(long lastEventMs) { this.lastEventMs = lastEventMs; }

        public int getViewCount() { return viewCount; }
        public void setViewCount(int viewCount) { this.viewCount = viewCount; }

        public int getClickCount() { return clickCount; }
        public void setClickCount(int clickCount) { this.clickCount = clickCount; }

        public int getCartAddCount() { return cartAddCount; }
        public void setCartAddCount(int cartAddCount) { this.cartAddCount = cartAddCount; }

        public int getPurchaseCount() { return purchaseCount; }
        public void setPurchaseCount(int purchaseCount) { this.purchaseCount = purchaseCount; }

        public double getTotalDwellTimeSec() { return totalDwellTimeSec; }
        public void setTotalDwellTimeSec(double totalDwellTimeSec) { this.totalDwellTimeSec = totalDwellTimeSec; }

        public List<String> getViewedItems() { return viewedItems; }
        public List<String> getClickedItems() { return clickedItems; }
        public List<String> getCartItems() { return cartItems; }
        public List<String> getSearchQueries() { return searchQueries; }

        public Map<String, Integer> getCategoryViews() { return categoryViews; }

        public Map<String, Object> toFeatureMap() {
            Map<String, Object> features = new HashMap<>();
            features.put("session_view_count", viewCount);
            features.put("session_click_count", clickCount);
            features.put("session_cart_add_count", cartAddCount);
            features.put("session_purchase_count", purchaseCount);

            double sessionDurationSec = (lastEventMs - sessionStartMs) / 1000.0;
            features.put("session_duration_sec", sessionDurationSec);
            features.put("session_dwell_time_sec", totalDwellTimeSec);
            features.put("session_ctr", viewCount > 0 ? (double) clickCount / viewCount : 0.0);

            int lastN = Math.min(10, viewedItems.size());
            features.put("last_viewed_items", viewedItems.subList(0, lastN));

            features.put("last_clicked_items", clickedItems.subList(0, Math.min(5, clickedItems.size())));
            features.put("cart_items", cartItems.subList(0, Math.min(10, cartItems.size())));
            features.put("search_queries", searchQueries.subList(0, Math.min(5, searchQueries.size())));

            Map<String, Integer> topCategories = new HashMap<>();
            categoryViews.entrySet().stream()
                    .sorted(Map.Entry.<String, Integer>comparingByValue().reversed())
                    .limit(5)
                    .forEach(e -> topCategories.put(e.getKey(), e.getValue()));
            features.put("top_categories", topCategories);

            features.put("_timestamp_ms", lastEventMs);
            features.put("_session_start_ms", sessionStartMs);

            return features;
        }
    }
}