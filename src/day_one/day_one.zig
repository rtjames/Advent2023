const std = @import("std");
const ascii = std.ascii;
const fmt = std.fmt;
const mem = std.mem;
const testing = std.testing;

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();

    const input_file = try std.fs.cwd().openFile("input.txt", .{ .mode = .read_only });
    defer input_file.close();

    var text_buffer: [21808]u8 = undefined;
    const bytes_written = try input_file.readAll(&text_buffer);
    _ = bytes_written;

    // Part 1: 55029
    const calibration_values_sum = readCalibrationDoc(&text_buffer, CalibrationSchema.version_1);
    try stdout.print("\nSum of Calibration Values Version 1: {d}\n", .{calibration_values_sum});

    // Part 2: 55686
    const calibration_values_sum_improved = readCalibrationDoc(&text_buffer, CalibrationSchema.version_2);
    try stdout.print("\nSum of Calibration Values Version 2: {d}\n", .{calibration_values_sum_improved});
}

const CalibrationSchema = enum { version_1, version_2 };

pub fn findCalibrationValueVersion1(line: []const u8) u8 {
    var have_first_number = false;
    var digits = "00".*;

    for (line) |character| {
        if (!ascii.isDigit(character)) {
            continue;
        }

        if (!have_first_number) {
            digits[0] = character;
            have_first_number = true;
        }

        digits[1] = character;
    }

    return fmt.parseUnsigned(u8, &digits, 10) catch 0;
}

test "find calibration value version 1" {
    try testing.expect(findCalibrationValueVersion1("1abc2") == 12);
    try testing.expect(findCalibrationValueVersion1("pqr3stu8vwx") == 38);
    try testing.expect(findCalibrationValueVersion1("a1b2c3d4e5f") == 15);
    try testing.expect(findCalibrationValueVersion1("treb7uchet") == 77);
}

test "read calibration doc version 1" {
    const expected: usize = 142;
    const calibration_doc =
        \\1abc2
        \\pqr3stu8vwx
        \\a1b2c3d4e5f
        \\treb7uchet
    ;
    const actual = readCalibrationDoc(calibration_doc, CalibrationSchema.version_1);
    try testing.expectEqual(expected, actual);
}

const digit_words = [_][]const u8{ "zero", "one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten" };

pub fn findCalibrationValueVersion2(line: []const u8) u8 {
    var have_first_number = false;
    var digits = "00".*;
    var index: usize = 0;

    while (index < line.len) : (index += 1) {
        const character = line[index];
        if (ascii.isDigit(character)) {
            if (!have_first_number) {
                digits[0] = character;
                have_first_number = true;
            }

            digits[1] = character;
            continue;
        }

        for (digit_words, 0..) |word, num| {
            if (!mem.startsWith(u8, line[index..], word)) {
                continue;
            }

            if (!have_first_number) {
                digits[0] = fmt.digitToChar(@intCast(num), fmt.Case.lower);
                have_first_number = true;
            }

            digits[1] = fmt.digitToChar(@intCast(num), fmt.Case.lower);
            break;
        }
    }

    return fmt.parseUnsigned(u8, &digits, 10) catch 0;
}

pub fn readCalibrationDoc(text: []const u8, schema: CalibrationSchema) usize {
    var calibration_value_sum: usize = 0;
    var lines_iterator = std.mem.split(u8, text, "\n");
    while (lines_iterator.next()) |line| {
        calibration_value_sum += switch (schema) {
            .version_1 => findCalibrationValueVersion1(line),
            .version_2 => findCalibrationValueVersion2(line),
        };
    }
    return calibration_value_sum;
}

test "find calibration value version 2" {
    try testing.expect(findCalibrationValueVersion2("two1nine") == 29);
    try testing.expect(findCalibrationValueVersion2("eightwothree") == 83);
    try testing.expect(findCalibrationValueVersion2("abcone2threexyz") == 13);
    try testing.expect(findCalibrationValueVersion2("xtwone3four") == 24);
    try testing.expect(findCalibrationValueVersion2("4nineeightseven2") == 42);
    try testing.expect(findCalibrationValueVersion2("zoneight234") == 14);
    try testing.expect(findCalibrationValueVersion2("7pqrstsixteen") == 76);
}

test "read calibration doc version 2" {
    const expected: usize = 281;
    const calibration_doc =
        \\two1nine
        \\eightwothree
        \\abcone2threexyz
        \\xtwone3four
        \\4nineeightseven2
        \\zoneight234
        \\7pqrstsixteen
    ;
    const actual = readCalibrationDoc(calibration_doc, CalibrationSchema.version_2);
    try testing.expectEqual(expected, actual);
}
