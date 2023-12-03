const std = @import("std");
const mem = std.mem;
const fmt = std.fmt;
const testing = std.testing;

const Color = struct {
    r: u8,
    g: u8,
    b: u8,
};

fn parseColorFromHand(hand: []const u8) Color {
    var result = Color{ .r = 0, .g = 0, .b = 0 };
    var splits = mem.split(u8, hand, ",");
    while (splits.next()) |split| {
        const color_with_label = mem.trim(u8, split, " ;");
        const separator = mem.indexOf(u8, color_with_label, " ") orelse 0;
        const color_value = fmt.parseUnsigned(u8, color_with_label[0..separator], 10) catch 0;
        if (mem.endsWith(u8, color_with_label, "red")) {
            result.r = color_value;
        } else if (mem.endsWith(u8, color_with_label, "green")) {
            result.g = color_value;
        } else if (mem.endsWith(u8, color_with_label, "blue")) {
            result.b = color_value;
        }
    }
    return result;
}

test "parse color from hand" {
    const expected = Color{ .r = 4, .g = 0, .b = 3 };
    const actual = parseColorFromHand("3 blue, 4 red;");
    try testing.expectEqual(expected, actual);
}

fn parseColorsFromGame(allocator: mem.Allocator, game: []const u8) mem.Allocator.Error![]Color {
    var colors = std.ArrayList(Color).init(allocator);
    errdefer colors.deinit();

    const colon_i = mem.indexOf(u8, game, ":") orelse 0;
    const hands = game[(colon_i + 1)..];
    var splits = mem.split(u8, hands, ";");
    while (splits.next()) |split| {
        const hand = mem.trim(u8, split, " ");
        const color = parseColorFromHand(hand);
        try colors.append(color);
    }

    return colors.toOwnedSlice();
}

test "parse colors from game" {
    const actual = try parseColorsFromGame(testing.allocator, "Game 1: 3 blue, 4 red; 1 red, 2 green, 6 blue; 2 green");
    defer testing.allocator.free(actual);
    try testing.expectEqual(Color{ .b = 3, .r = 4, .g = 0 }, actual[0]);
    try testing.expectEqual(Color{ .r = 1, .g = 2, .b = 6 }, actual[1]);
    try testing.expectEqual(Color{ .g = 2, .r = 0, .b = 0 }, actual[2]);
}

fn doesColorContain(container: Color, contents: Color) bool {
    return container.r >= contents.r and container.g >= contents.g and container.b >= contents.b;
}

fn sumValidGames(allocator: mem.Allocator, games: []const u8, compare_color: Color) mem.Allocator.Error!usize {
    var valid_games_sum: usize = 0;
    var games_iterator = std.mem.split(u8, games, "\n");
    var game_number: usize = 1;
    while (games_iterator.next()) |game| {
        const colors = try parseColorsFromGame(allocator, game);
        defer allocator.free(colors);
        var is_game_valid = true;
        for (colors) |color| {
            if (!doesColorContain(compare_color, color)) {
                is_game_valid = false;
                break;
            }
        }
        if (is_game_valid) {
            valid_games_sum += game_number;
        }
        game_number += 1;
    }
    return valid_games_sum;
}

test "sum valid games" {
    const expected: usize = 8;
    const games =
        \\Game 1: 3 blue, 4 red; 1 red, 2 green, 6 blue; 2 green
        \\Game 2: 1 blue, 2 green; 3 green, 4 blue, 1 red; 1 green, 1 blue
        \\Game 3: 8 green, 6 blue, 20 red; 5 blue, 4 red, 13 green; 5 green, 1 red
        \\Game 4: 1 green, 3 red, 6 blue; 3 green, 6 red; 3 green, 15 blue, 14 red
        \\Game 5: 6 red, 1 blue, 3 green; 2 blue, 1 red, 2 green
    ;
    const compare_color = Color{ .r = 12, .g = 13, .b = 14 };
    const actual: usize = try sumValidGames(testing.allocator, games, compare_color);
    try testing.expectEqual(expected, actual);
}

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();

    const input_file = try std.fs.cwd().openFile("input.txt", .{ .mode = .read_only });
    defer input_file.close();

    var text_buffer: [10476]u8 = undefined;
    const bytes_written = try input_file.readAll(&text_buffer);
    _ = bytes_written;

    var allocator_src = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(!(allocator_src.deinit() == .leak));

    const compare_color = Color{ .r = 12, .g = 13, .b = 14 };
    // 2317
    const valid_games_sum = try sumValidGames(allocator_src.allocator(), &text_buffer, compare_color);
    try stdout.print("\nSum of Valid Games: {d}\n", .{valid_games_sum});
    // 74804
    const powers_sum = try sumPowersOfGames(allocator_src.allocator(), &text_buffer);
    try stdout.print("\nSum of Powers: {d}\n", .{powers_sum});
}

fn findPower(colors: []Color) usize {
    var red: usize = 0;
    var green: usize = 0;
    var blue: usize = 0;
    for (colors) |color| {
        if (color.r > red) {
            red = color.r;
        }
        if (color.g > green) {
            green = color.g;
        }
        if (color.b > blue) {
            blue = color.b;
        }
    }
    return red * blue * green;
}

fn sumPowersOfGames(allocator: mem.Allocator, games: []const u8) mem.Allocator.Error!u128 {
    var powers_sum: u128 = 0;
    var games_iterator = std.mem.split(u8, games, "\n");
    while (games_iterator.next()) |game| {
        const colors = try parseColorsFromGame(allocator, game);
        defer allocator.free(colors);
        powers_sum += findPower(colors);
    }
    return powers_sum;
}

test "sum powers of games" {
    const expected: u128 = 2286;
    const games =
        \\Game 1: 3 blue, 4 red; 1 red, 2 green, 6 blue; 2 green
        \\Game 2: 1 blue, 2 green; 3 green, 4 blue, 1 red; 1 green, 1 blue
        \\Game 3: 8 green, 6 blue, 20 red; 5 blue, 4 red, 13 green; 5 green, 1 red
        \\Game 4: 1 green, 3 red, 6 blue; 3 green, 6 red; 3 green, 15 blue, 14 red
        \\Game 5: 6 red, 1 blue, 3 green; 2 blue, 1 red, 2 green
    ;
    const actual: u128 = try sumPowersOfGames(testing.allocator, games);
    try testing.expectEqual(expected, actual);
}
