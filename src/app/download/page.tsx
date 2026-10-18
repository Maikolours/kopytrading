import { redirect } from "next/navigation";
import { getServerSession } from "next-auth/next";
import { authOptions } from "@/lib/auth";

export default async function DownloadRedirectPage({
  searchParams,
}: {
  searchParams: Promise<{ p?: string }>;
}) {
  const params = await searchParams;
  const session = await getServerSession(authOptions);

  if (params?.p) {
    if (!session?.user) {
      redirect(`/login?callbackUrl=/download?p=${params.p}`);
    }
    redirect(`/api/download/${params.p}?type=ex5`);
  }
  redirect("/dashboard");
}
