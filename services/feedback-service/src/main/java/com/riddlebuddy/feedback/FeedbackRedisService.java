package com.riddlebuddy.feedback;

import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Service;

@Service
public class FeedbackRedisService {

    private final StringRedisTemplate redis;

    public FeedbackRedisService(StringRedisTemplate redis) {
        this.redis = redis;
    }

    public void addFeedback(String jokeId, boolean liked) {
        String key = liked
                ? "joke:" + jokeId + ":like"
                : "joke:" + jokeId + ":dislike";

        redis.opsForValue().increment(key);
    }

    public long getLikes(String jokeId) {
        return getCount("joke:" + jokeId + ":like");
    }

    public long getDislikes(String jokeId) {
        return getCount("joke:" + jokeId + ":dislike");
    }

    private long getCount(String key) {
        String value = redis.opsForValue().get(key);
        return value == null ? 0 : Long.parseLong(value);
    }
}
