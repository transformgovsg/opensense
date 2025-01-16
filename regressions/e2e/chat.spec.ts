import { expect, test } from '@playwright/test';
import { SensePage } from '../sense_page';

const LONGER_TIMEOUT = 30_000;

test('Chat Experience', async ({ page, context }) => {
    const sensePage = new SensePage(page);
    await test.step('Ask "What data do you have?" and shows a table', async () => {
        await sensePage.goto();
        await expect(
            page.getByText('Go ahead, ask a question!'),
        ).toBeVisible();
        await sensePage.typeAndSendMessage('what data do you have');

        await expect(
            page.getByRole('progressbar').first(),
            'Progress bar to render',
        ).toBeVisible({ timeout: LONGER_TIMEOUT });
        await page
            .getByRole('columnheader')
            .nth(0)
            .waitFor({ timeout: LONGER_TIMEOUT });
        await expect(
            page.getByRole('columnheader', { name: 'Column Name' }).nth(0),
        ).toBeVisible();
        await expect(
            page.getByRole('columnheader', { name: 'Display Name' }).nth(0),
        ).toBeVisible();
        await expect(
            page.getByRole('columnheader', { name: 'Type' }).nth(0),
        ).toBeVisible();
    });

    await test.step('Successful query response with SQL statement, copy button and result table ', async () => {
        await context.grantPermissions(['clipboard-read', 'clipboard-write']);
        await sensePage.goto();
        await expect(
            page.getByText('Go ahead, ask a question!'),
        ).toBeVisible();
        await sensePage.typeAndSendMessage(
            'run `SELECT ' +
                '1.0/3 as float_value, ' +
                '2 as integer_value,' +
                '20000/3.0 as large_float_value,' +
                '20000 as large_int_value' +
                '` verbatim.',
        );

        await expect(
            page.locator('div').filter({ hasText: /^sql$/ }).nth(0),
            'SQL statement to render',
        ).toBeVisible({ timeout: LONGER_TIMEOUT });
        await page
            .locator('div')
            .filter({ hasText: /^sql$/ })
            .getByLabel('Copy')
            .click({ timeout: LONGER_TIMEOUT });
        let clipboardContent = await sensePage.getClipboardContent();
        expect(clipboardContent, 'Copy button to copy SQL statement').toMatch(
            /^SELECT.*/,
        );
        await expect(
            page.getByRole('heading', {
                name: 'First 1 of 1 rows (Truncated)',
            }),
            'Row count to render',
        ).toBeVisible({ timeout: LONGER_TIMEOUT });
        const firstTable = page.getByRole('table').nth(0);
        await expect(firstTable).toBeVisible({ timeout: 50_000 });
        await expect(
            firstTable.getByRole('columnheader', { name: 'Column Name' }),
            'Data table to render without column header, "Column Name"',
        ).not.toBeVisible();
        const firstColumn = firstTable.getByRole('row').nth(1);
        await expect(
            firstColumn.getByRole('cell').nth(0),
            'Decimal numbers rounded to 2 places',
        ).toHaveText('0.33');
        await expect(
            firstColumn.getByRole('cell').nth(1),
            'Integer numbers to render without decimal points',
        ).toHaveText('2');
        await expect(
            firstColumn.getByRole('cell').nth(2),
            'Decimal numbers to render with commas',
        ).toHaveText('6,666.67');
        await expect(
            firstColumn.getByRole('cell').nth(3),
            'Integer numbers to render with commas',
        ).toHaveText('20,000');
        await expect(
            page.getByRole('link', { name: /^dataco-.*/ }).nth(0),
            'Download button to render',
        ).toBeVisible({ timeout: LONGER_TIMEOUT });
        await expect(
            page.locator('#stop-button'),
            'Stop button to disppear upon clicking',
        ).not.toBeVisible();
        await page.getByLabel('Copy').last().click();
        clipboardContent = await sensePage.getClipboardContent();
        expect(
            clipboardContent,
            'Copy button to copy more than SQL statement',
        ).not.toMatch(/^SELECT.*/);
        expect(
            clipboardContent,
            'Copy button to copy the entire message',
        ).toMatch(/.*SELECT.*/g);
    });

    await test.step('If no rows are found, renders no rows message', async () => {
        await sensePage.goto();
        await expect(
            page.getByText('Go ahead, ask a question!'),
        ).toBeVisible();
        await sensePage.typeAndSendMessage(
            'Select the first table but 0 rows. Yes 0 rows. Limit 0.',
        );

        await page
            .getByText(/The query has returned no rows at all.*/)
            .waitFor({ timeout: LONGER_TIMEOUT });

        await expect(
            page.getByText(/The query has returned no rows at all.*/),
        ).toBeVisible();
    });

    await test.step('Stop button renders while LLM is working, and stops the task when clicked', async () => {
        await sensePage.goto();
        await expect(
            page.getByText('Go ahead, ask a question!'),
        ).toBeVisible();
        const stopTask = page.locator('#stop-button');
        const sendMessage = page.getByRole('button').nth(3); // paiseh got no other selector
        await sensePage.typeAndSendMessage('hello');

        await expect(stopTask).toBeVisible({ timeout: LONGER_TIMEOUT });
        await stopTask.click();
        await expect(page.getByText('Task manually stopped.')).toBeVisible();
        await expect(
            stopTask,
            'Stop button to disppear upon clicking',
        ).not.toBeVisible();
        await expect(
            sendMessage,
            'Send message button to render',
        ).toBeVisible();
    });

    await test.step('Scroll to bottom appears and works', async () => {
        await sensePage.goto();
        await expect(
            page.getByText('Go ahead, ask a question!'),
        ).toBeVisible();
        await sensePage.typeAndSendMessage('what data do you have');
        await expect(page.getByLabel('Copy')).toBeVisible({
            timeout: LONGER_TIMEOUT,
        });
        await page.getByText('what data do you have').hover();

        const scrollToBottom = page.locator('.MuiIconButton-sizeSmall').nth(0);
        await expect(
            scrollToBottom,
            'ScrollToBottom button to render',
        ).toBeVisible({ timeout: 50_000 });
        await scrollToBottom.click();
        await expect(
            scrollToBottom,
            'ScrollToBottom button to disappear',
        ).toHaveCount(0);
    });

    await test.step('New chat button clears current chat and render new chat', async () => {
        await sensePage.goto();
        await expect(
            page.getByText('Go ahead, ask a question!'),
        ).toBeVisible();
        await sensePage.typeAndSendMessage('what data do you have');
        await expect(page.getByLabel('Copy')).toBeVisible({
            timeout: LONGER_TIMEOUT,
        });
        await page.locator('#new-chat-button').click();
        await page.getByRole('button', { name: 'Confirm' }).click();
        await expect(
            page.getByText('Go ahead, ask a question!'),
            'Chat session to reset',
        ).toBeVisible();
    });
});
