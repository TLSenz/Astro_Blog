import ReactMarkdown from "react-markdown";
import { Prism as SyntaxHighlighter } from "react-syntax-highlighter";
import { dracula } from "react-syntax-highlighter/dist/cjs/styles/prism";
import '../styles/global.css'

type Props = {
  content: string;
  title?: string;
  author?: string;
  date?: string | Date;
};

export default function MarkdownRenderer({ content, title, author, date }: Props) {
  const displayDate = date ? new Date(date).toDateString() : undefined;
  return (
    <article className="prose prose-invert mx-auto max-w-3xl px-4 py-8 leading-relaxed prose-headings:font-semibold prose-img:rounded-lg prose-pre:rounded-lg prose-pre:p-4 prose-code:text-sm">
      {title && <h1 className="text-center">{title}</h1>}
      {(author || displayDate) && (
        <p className="mt-2 text-center text-sm text-gray-400">
          {author && <span>by {author}</span>}
          {author && displayDate && <span> • </span>}
          {displayDate && (
            <time dateTime={new Date(date as any).toISOString()}>{displayDate}</time>
          )}
        </p>
      )}
      <ReactMarkdown
        components={{
          code({ inline, className, children, ...props }: any) {
            const match = /language-(\w+)/.exec(className || "");
            return !inline && match ? (
              <SyntaxHighlighter
                style={dracula}
                language={match[1]}
                PreTag="div"
                {...props}
              >
                {String(children).replace(/\n$/, "")}
              </SyntaxHighlighter>
            ) : (
              <code className={className || ''} {...props}>
                {children}
              </code>
            );
          },
        }}
      >
        {content}
      </ReactMarkdown>
    </article>
  );
}
