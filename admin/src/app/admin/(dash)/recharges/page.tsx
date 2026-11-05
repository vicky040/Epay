import { TxnReview } from '@/components/TxnReview';

export const dynamic = 'force-dynamic';

export default async function RechargesPage({
  searchParams,
}: {
  searchParams: Promise<{ status?: string }>;
}) {
  const { status } = await searchParams;
  return (
    <TxnReview
      type="recharge"
      title="Recharges"
      subtitle="Confirm deposits to credit the user's recharge balance"
      approveLabel="Confirm & credit"
      status={status ?? 'pending'}
    />
  );
}
