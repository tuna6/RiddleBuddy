package com.riddlebuddy.feedback;

import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/feedback")
public class FeedbackController {

    private final FeedbackRedisService service;

    public FeedbackController(FeedbackRedisService service) {
        this.service = service;
    }

    @PostMapping
    public void submit(@RequestBody Map<String, Object> body) {
        String jokeId = body.get("jokeId").toString();
        boolean liked = Boolean.parseBoolean(body.get("liked").toString());
        service.addFeedback(jokeId, liked);
    }

    @GetMapping("/{jokeId}")
    public Map<String, Long> get(@PathVariable String jokeId) {
        return Map.of(
                "likes", service.getLikes(jokeId),
                "dislikes", service.getDislikes(jokeId)
        );
    }
}
