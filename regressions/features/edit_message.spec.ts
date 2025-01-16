import { expect, test } from '@playwright/test';
import { SensePage } from '../sense_page';

const LONGER_TIMEOUT = 50_000;

test('Edit Message', async ({ page }) => {
    const sensePage = new SensePage(page);
    await sensePage.goto();
    await expect(page.getByText('Go ahead, ask a question!')).toBeVisible();
    await sensePage.typeAndSendMessage('what data do you have');
    await expect(page.getByLabel('Copy')).toBeVisible({
        timeout: LONGER_TIMEOUT,
    });

    await page.getByText('what data do you have').hover();
    await page.locator('button.edit-icon').click();
    await page.getByText('what data do you have').click();
    const textarea = page.locator('#edit-chat-input');
    await textarea.clear();
    await textarea.fill('hello');
    await page.getByRole('button', { name: 'Confirm' }).click();
    await expect(
        page.getByText('Hello! How can I assist you'),
        'New reply to render after sending edited message',
    ).toBeVisible({ timeout: LONGER_TIMEOUT });
});
