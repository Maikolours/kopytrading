import { redirect } from "next/navigation";

export default async function DownloadRedirectPage({
  searchParams,
}: {
  searchParams: Promise<{ p?: string }>;
}) {
  const params = await searchParams;
  if (params?.p) {
    redirect(`/api/download/${params.p}?type=ex5`);
  }
  redirect("/dashboard");
}
