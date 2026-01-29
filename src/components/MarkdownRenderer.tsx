import ReactMarkdown from "react-markdown";
import remarkGfm from "remark-gfm";

interface Props {
  content: string;
  title: string;
}

export default function MarkdownRenderer({ content, title }: Props) {
  return (
    <article className="prose lg:prose-xl mx-auto">
      <h1>{title}</h1>
      <ReactMarkdown remarkPlugins={[remarkGfm]}>{content}</ReactMarkdown>
    </article>
  );
}
