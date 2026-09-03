"""Focused commands and shared primitives for Jujutsu workflows."""

from .diff import entrypoint as jj_diff_entrypoint
from .get import entrypoint as jj_get_entrypoint

__all__ = ["jj_diff_entrypoint", "jj_get_entrypoint"]
