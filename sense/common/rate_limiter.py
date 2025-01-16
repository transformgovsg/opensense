import time
from collections import deque

from cachetools import TTLCache

from sense.common.config import settings


class RateLimiter:
    def __init__(self, limit=8, per=300):
        self.limit = limit
        self.per = per
        self.cache = TTLCache(maxsize=2048, ttl=per)

    def is_allowed(self, user_id):
        current_timestamp = int(time.time())
        user_timestamps = self.cache.get(user_id)

        if not user_timestamps:
            self.cache[user_id] = deque()
            self.cache[user_id].append(current_timestamp)
            return True

        if current_timestamp - user_timestamps[0] > self.per:
            user_timestamps.popleft()

        if len(user_timestamps) < self.limit:
            user_timestamps.append(current_timestamp)
            del self.cache[user_id]
            self.cache[user_id] = user_timestamps
            return True
        return False


rate_limiter = RateLimiter(
    limit=settings.rate_limit_count,
    per=settings.rate_limit_interval,
)
