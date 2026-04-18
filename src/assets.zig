const rl = @import("raylib");

pub var audio_blips: [5]rl.Sound = undefined;

pub var texture_star: rl.Texture = undefined;

pub fn deinit() void
{
    for(audio_blips) |i|
    {
        i.unload();
    }

    texture_star.unload();
}

pub fn init() !void
{
    audio_blips[0] = try rl.loadSound("cont/blip_1.ogg");
    audio_blips[1] = try rl.loadSound("cont/blip_2.ogg");
    audio_blips[2] = try rl.loadSound("cont/blip_3.ogg");
    audio_blips[3] = try rl.loadSound("cont/blip_4.ogg");
    audio_blips[4] = try rl.loadSound("cont/blip_5.ogg");

    texture_star = try rl.loadTexture("cont/star.png");
}