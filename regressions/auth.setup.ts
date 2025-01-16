import { expect, test as setup } from "@playwright/test";
import * as path from "node:path";
import { login } from "./utils/auth";

export const authFile = path.join(__dirname, "../playwright/.auth/user.json");

setup("authenticate", async ({ page }) => {
    await login(page);
    const messageInput = page.getByPlaceholder("Type your message here...");
    await expect(messageInput).toBeVisible(); // Check that the input is visible
    await page.context().storageState({ path: authFile });
});
