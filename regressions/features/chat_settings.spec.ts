import { expect, Page, test } from "@playwright/test";
import { SensePage } from "../sense_page";

test.skip("user can change chat settings", async ({ page }) => {
    // test not requried after removal of Model and Memory Length options
    const sensePage = new SensePage(page);
    await test.step("go to chat playground and select chat setting option", async () => {
        await sensePage.goto();
        await sensePage.openChatSettings();
        await expect(page.getByText("Settings panel")).toBeVisible();
    });

    await test.step("tweak chat settings", async () => {
        await sensePage.changeChatSettings();
    });

    await test.step("validate chat settings are saved", async () => {
        await sensePage.openChatSettings();
        await expect.soft(page.getByLabel("gpt-4-1106-preview")).toBeVisible();
        await expect
            .soft(page.getByLabel("Memory Length (Message Count)"))
            .toHaveValue("15");
    });
});
