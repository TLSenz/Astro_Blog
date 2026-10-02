import type { CollectionEntry } from 'astro:content';

export const DEFAULT_LOCALE = 'en';

const LOCALE_SUFFIX = /\.([a-z]{2}(?:-[A-Z]{2})?)$/;

export function parsePostId(id: string): { base: string; locale: string } {
  const match = LOCALE_SUFFIX.exec(id);
  if (!match) return { base: id, locale: DEFAULT_LOCALE };
  return { base: id.slice(0, match.index), locale: match[1] };
}

export function groupTranslations(
  posts: CollectionEntry<'blog'>[]
): Map<string, CollectionEntry<'blog'>[]> {
  const groups = new Map<string, CollectionEntry<'blog'>[]>();
  for (const post of posts) {
    const { base } = parsePostId(post.id);
    const group = groups.get(base) ?? [];
    group.push(post);
    groups.set(base, group);
  }
  return groups;
}
