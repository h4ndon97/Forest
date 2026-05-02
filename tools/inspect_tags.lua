-- Aseprite Lua 스크립트: 활성 스프라이트의 태그 정보를 환경변수로 지정된 파일에 TSV로 출력.
-- 출력 포맷: <tag_name>\t<from_frame_0_indexed>\t<to_frame_0_indexed>
-- 호출: aseprite -b <file.aseprite> --script tools/inspect_tags.lua
-- 환경변수: ASE_TAG_OUT (대상 파일 경로)

local sprite = app.activeSprite
if sprite == nil then return end

local outpath = os.getenv("ASE_TAG_OUT")
if outpath == nil then return end

local out = io.open(outpath, "w")
if out == nil then return end

for _, tag in ipairs(sprite.tags) do
    -- Lua API frameNumber: 1-based. Aseprite CLI --frame-range: 0-based.
    local fromIdx = tag.fromFrame.frameNumber - 1
    local toIdx = tag.toFrame.frameNumber - 1
    out:write(tag.name .. "\t" .. fromIdx .. "\t" .. toIdx .. "\n")
end
out:close()
