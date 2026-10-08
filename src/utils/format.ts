export function estimateReadingTime(text?: string): number {
  if (!text) return 0;
  const words = text.trim().split(/\s+/).length;
  return Math.max(1, Math.ceil(words / 220));
}

const DATE_LOCALES: Record<string, string> = {
  en: 'en-US',
  de: 'de-DE',
};

export function formatDate(date: Date, locale: string): string {
  return date.toLocaleDateString(DATE_LOCALES[locale] ?? locale, {
    year: 'numeric',
    month: 'long',
    day: 'numeric',
  });
}

export function formatDateShort(date: Date, locale: string): string {
  return date.toLocaleDateString(DATE_LOCALES[locale] ?? locale, {
    year: 'numeric',
    month: 'short',
    day: 'numeric',
  });
}
