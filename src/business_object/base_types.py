from enum import Enum


class Sport(str, Enum):
    RUNNING = "running"
    CYCLING = "cycling"
    HIKING = "hiking"
    SWIMMING = "swimming"


class Privacy(str, Enum):
    PRIVATE = "private"
    FRIENDS = "friends"
    PUBLIC = "public"
