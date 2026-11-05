import { Button, Card, CardHeader, Field, Input, PageTitle } from '@/components/ui';
import { DEFAULT_SETTINGS, getSettings } from '@/lib/earnings';
import { changeAdminPassword, saveSettings } from '@/app/admin/actions';
import { currentAdmin } from '@/lib/auth';

export const dynamic = 'force-dynamic';

export default async function SettingsPage() {
  const saved = await getSettings();
  const admin = await currentAdmin();
  const v = (k: string) => saved[k] ?? DEFAULT_SETTINGS[k] ?? '';

  return (
    <>
      <PageTitle
        title="Settings"
        subtitle="Platform-wide values used by the app and the backend"
      />

      <form action={saveSettings} className="grid gap-5 lg:grid-cols-2">
        <Card>
          <CardHeader title="Brand" />
          <div className="space-y-4 p-5">
            <Field label="App name">
              <Input name="appName" defaultValue={v('appName')} />
            </Field>
            <Field label="Public URL" hint="Used to build invite links">
              <Input name="publicUrl" defaultValue={v('publicUrl')} />
            </Field>
            <Field label="Support hours">
              <Input name="supportHours" defaultValue={v('supportHours')} />
            </Field>
            <Field label="Telegram channel">
              <Input name="telegramUrl" defaultValue={v('telegramUrl')} />
            </Field>
          </div>
        </Card>

        <Card>
          <CardHeader
            title="Money"
            subtitle="Limits enforced by the recharge and withdraw endpoints"
          />
          <div className="space-y-4 p-5">
            <div className="grid grid-cols-2 gap-4">
              <Field label="Minimum recharge (₹)">
                <Input name="minRecharge" type="number" step="0.01" defaultValue={v('minRecharge')} />
              </Field>
              <Field label="Minimum withdrawal (₹)">
                <Input name="minWithdraw" type="number" step="0.01" defaultValue={v('minWithdraw')} />
              </Field>
            </div>
            <Field
              label="Withdrawal tax (%)"
              hint="Deducted from the payout and shown to the user before they confirm"
            >
              <Input
                name="withdrawTaxPercent"
                type="number"
                step="0.01"
                defaultValue={v('withdrawTaxPercent')}
              />
            </Field>
            <Field label="Default blog reward (₹)">
              <Input name="blogReward" type="number" step="0.01" defaultValue={v('blogReward')} />
            </Field>
          </div>
        </Card>

        <Card className="lg:col-span-2">
          <CardHeader
            title="Referrals"
            subtitle="Rebate paid to each upline level on every purchase"
          />
          <div className="grid gap-4 p-5 sm:grid-cols-4">
            <Field label="Activation reward (₹)">
              <Input
                name="activationReward"
                type="number"
                step="0.01"
                defaultValue={v('activationReward')}
              />
            </Field>
            <Field label="Level 1 rebate (%)">
              <Input name="rebateL1" type="number" step="0.01" defaultValue={v('rebateL1')} />
            </Field>
            <Field label="Level 2 rebate (%)">
              <Input name="rebateL2" type="number" step="0.01" defaultValue={v('rebateL2')} />
            </Field>
            <Field label="Level 3 rebate (%)">
              <Input name="rebateL3" type="number" step="0.01" defaultValue={v('rebateL3')} />
            </Field>
          </div>
        </Card>

        <div className="lg:col-span-2">
          <Button type="submit">Save settings</Button>
        </div>
      </form>

      <Card className="mt-5">
        <CardHeader
          title="Your admin password"
          subtitle={`Signed in as ${admin?.phone ?? ''}. Change the seeded password before going live.`}
        />
        <form
          action={changeAdminPassword}
          className="grid gap-4 p-5 sm:grid-cols-3"
        >
          <Field label="Current password">
            <Input
              name="currentPassword"
              type="password"
              autoComplete="current-password"
              required
            />
          </Field>
          <Field label="New password" hint="At least 8 characters">
            <Input
              name="newPassword"
              type="password"
              autoComplete="new-password"
              minLength={8}
              required
            />
          </Field>
          <Field label="Confirm new password">
            <Input
              name="confirmPassword"
              type="password"
              autoComplete="new-password"
              minLength={8}
              required
            />
          </Field>
          <div className="sm:col-span-3">
            <Button type="submit">Change password</Button>
          </div>
        </form>
      </Card>
    </>
  );
}
