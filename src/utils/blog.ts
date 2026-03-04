import type { CollectionEntry } from 'astro:content';

export type BlogPost = CollectionEntry<'blog'>;

export function formatDate(date: Date): string {
  return new Intl.DateTimeFormat('en-US', {
    year: 'numeric',
    month: 'short',
    day: 'numeric',
  }).format(date);
}

export function sortPostsByDate(posts: BlogPost[]): BlogPost[] {
  return [...posts].sort(
    (a, b) => b.data.pubDate.getTime() - a.data.pubDate.getTime(),
  );
}

export function calculateReadingTime(content: string, wordsPerMinute = 200): number {
  const words = content.trim().split(/\s+/).filter(Boolean).length;
  return Math.max(1, Math.ceil(words / wordsPerMinute));
}

export function extractUniqueTags(posts: BlogPost[]): string[] {
  const tagSet = new Set<string>();

  for (const post of posts) {
    for (const tag of post.data.tags ?? []) {
      tagSet.add(tag.toLowerCase());
    }
  }

  return [...tagSet].sort((a, b) => a.localeCompare(b));
}

export function getRelatedPosts(
  currentPost: BlogPost,
  allPosts: BlogPost[],
  limit = 2,
): BlogPost[] {
  const currentTags = new Set((currentPost.data.tags ?? []).map((tag) => tag.toLowerCase()));

  if (currentTags.size === 0) {
    return sortPostsByDate(
      allPosts.filter((post) => post.slug !== currentPost.slug),
    ).slice(0, limit);
  }

  return sortPostsByDate(
    allPosts
      .filter((post) => post.slug !== currentPost.slug)
      .filter((post) =>
        (post.data.tags ?? []).some((tag) => currentTags.has(tag.toLowerCase())),
      ),
  ).slice(0, limit);
}
