import { TxnReview } from '@/components/TxnReview';

export const dynamic = 'force-dynamic';

export default async function WithdrawalsPage({
  searchParams,
}: {
  searchParams: Promise<{ status?: string }>;
}) {
  const { status } = await searchParams;
  return (
    <TxnReview
      type="withdraw"
      title="Withdrawals"
      subtitle="Funds are already held. Approving marks the payout as sent; rejecting refunds the user."
      approveLabel="Mark as paid"
      status={status ?? 'pending'}
    />
  );
}
