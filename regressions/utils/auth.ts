import { Page } from "@playwright/test";

export async function login(page: Page) {
    await page.goto("/");

    await page
        .getByRole("textbox", { name: "Username" })
        .waitFor({ timeout: 10000 });

    await page.getByRole("textbox", { name: "Username" }).click();
    await page
        .getByRole("textbox", { name: "Username" })
        .fill(process.env.E2E_USERNAME);

    await page.getByRole("textbox", { name: "Password" }).click();
    await page
        .getByRole("textbox", { name: "Password" })
        .fill(process.env.E2E_PASSWORD);

    await page.getByRole("button", { name: "submit" }).click();

    await page.waitForNavigation({ timeout: 30000 });
}
