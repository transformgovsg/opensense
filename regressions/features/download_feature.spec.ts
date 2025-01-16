import { expect, test } from '@playwright/test';
import { SensePage } from '../sense_page';
import { parseCSV } from '../utils/parse_csv';

const LONGER_TIMEOUT = 50_000;
const SIX_MINUTES = 6 * 60 * 1000;

test('Download feature', async ({ page }) => {
    test.setTimeout(SIX_MINUTES + 60000);
    const sensePage = new SensePage(page);
    await sensePage.goto();
    await expect(page.getByText('Go ahead, ask a question!')).toBeVisible();
    await sensePage.typeAndSendMessage(
        'run `SELECT ' +
            '1.0/3 as float_value, ' +
            '2 as integer_value,' +
            '20000/3.0 as large_float_value,' +
            '20000 as large_int_value' +
            '` verbatim.',
    );

    const downloadButton = page
        .getByRole('link', { name: /^dataco-.*/ })
        .nth(0);
    await expect(downloadButton, 'Download button to render').toBeVisible({
        timeout: LONGER_TIMEOUT,
    });

    const downloadPromise = page.waitForEvent('download');
    await downloadButton.click();
    const download = await downloadPromise;
    const downloadPath = await download.path();
    const records = await parseCSV(downloadPath);

    expect(records, 'CSV to contain the queried output').toEqual({
        float_value: '0.33',
        integer_value: '2',
        large_float_value: '6,666.67',
        large_int_value: '20,000',
    });

    const downloadUrl = download.url();
    await page.waitForTimeout(SIX_MINUTES);
    const response = await page.request.get(downloadUrl);

    expect(
        await response.text(),
        'Expired download link to return Internal Server Error',
    ).toContain('Internal Server Error');
});
