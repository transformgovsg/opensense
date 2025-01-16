import fs from 'fs';
import readline from 'readline';

function parseLine(line: string): string[] {
    const result: string[] = [];
    let current = '';
    let inQuotes = false;

    for (let char of line) {
        if (char === '"') {
            inQuotes = !inQuotes;
        } else if (char === ',' && !inQuotes) {
            result.push(current.trim());
            current = '';
        } else {
            current += char;
        }
    }
    result.push(current.trim());
    return result;
}

const parseCSV = async (filePath: string): Promise<Record<string, string>> => {
    const fileStream = fs.createReadStream(filePath);
    const rl = readline.createInterface({
        input: fileStream,
        crlfDelay: Infinity,
    });

    const record: Record<string, string> = {};
    let headers: string[] | undefined;

    for await (const line of rl) {
        const values = parseLine(line);
        if (!headers) {
            headers = values;
        } else {
            headers.forEach((header, index) => {
                record[header.trim()] = values[index];
            });
        }
    }

    return record;
};

export { parseCSV };
