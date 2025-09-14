--[[ 
_G.WebhookURL = "" 
_G.Time = 300
]]
local HttpService = game:GetService("HttpService")
local startTime = tick()
local webhookURL = _G.WebhookURL
local players = game:GetService("Players")
local replicatedStorage = game:GetService("ReplicatedStorage")
local nguoiChoi = players.LocalPlayer

-- Hàm lấy số lượng vật phẩm
local function laySoLuongVatPham(tenVatPham)
    -- Sử dụng WaitForChild để đảm bảo thư mục Remotes đã được tải xong
    local remotesFolder = replicatedStorage:WaitForChild("Remotes", 5)

    if not remotesFolder then
        warn("Lỗi: Không tìm thấy thư mục 'Remotes' trong ReplicatedStorage sau 5 giây!")
        return 0
    end

    local remote = remotesFolder:FindFirstChild("CommF_")
    if not remote then
        warn("Lỗi: Không tìm thấy RemoteFunction 'CommF_' bên trong thư mục Remotes!")
        return 0
    end

    local thanhCong, khoDo = pcall(function()
        return remote:InvokeServer("getInventory")
    end)

    if not thanhCong or type(khoDo) ~= "table" then
        warn("Lỗi: Không thể lấy kho đồ từ máy chủ hoặc dữ liệu trả về không phải là một bảng.")
        return 0
    end

    -- Duyệt qua bảng kho đồ để tìm vật phẩm theo tên
    for _, vatPham in pairs(khoDo) do
        -- Kiểm tra xem có đúng tên vật phẩm và có thuộc tính 'Count' không
        if vatPham.Name and vatPham.Name == tenVatPham and vatPham.Count then
            return vatPham.Count
        end
    end
    
    -- Nếu không tìm thấy vật phẩm trong vòng lặp, trả về 0
    return 0
end

-- Hàm lấy tất cả tên vật phẩm trong kho đồ và trả về một chuỗi
local function layTenVatPhamTrongBackpack()
    local itemNames = {}
    local backpack = nguoiChoi:WaitForChild("Backpack", 5)
    
    if not backpack then
        warn("Lỗi: Không tìm thấy Backpack sau 5 giây!")
        return "Không tìm thấy kho đồ."
    end
    
    local items = backpack:GetChildren()
    
    -- Duyệt qua từng vật phẩm và thêm tên vào bảng
    for _, item in pairs(items) do
        table.insert(itemNames, item.Name)
    end
    
    -- Nếu không có vật phẩm nào, trả về thông báo
    if #itemNames == 0 then
        return "```Kho đồ trống.```"
    else
        -- 1. Nối các tên vật phẩm thành một chuỗi, phân tách bằng dấu phẩy và xuống dòng.
        local concatenatedItems = table.concat(itemNames, ",\n")
        -- 2. Thêm dấu ``` vào trước và sau chuỗi vừa tạo.
        return "```\n" .. concatenatedItems .. "\n```"
    end
end

-- Hàm gửi tin nhắn tới Discord
local function sendToDiscord()
    -- Lấy dữ liệu từ game
    local a = nguoiChoi.PlayerGui:WaitForChild("Main"):WaitForChild("Beli").Text
    local b = nguoiChoi.PlayerGui:WaitForChild("Main"):WaitForChild("Fragments").Text
    local c = tostring(laySoLuongVatPham("Summer Token"))
    local d = tostring(laySoLuongVatPham("Oni Token"))
    local e = tostring(laySoLuongVatPham("Bones"))
--    local f = tostring(laySoLuongVatPham("Conjured Cocoa"))
    local g = tostring(laySoLuongVatPham("Celestial Token"))
    local elapsedTime = math.floor(tick() - startTime)
    local hours = string.format("%02d", math.floor(elapsedTime / 3600))
    local minutes = string.format("%02d", math.floor((elapsedTime % 3600) / 60))
    local seconds = string.format("%02d", elapsedTime % 60)
    local formattedTime = "Thời gian chơi: " .. hours .. " giờ " .. minutes .. " phút " .. seconds .. " giây"
    local v = nguoiChoi.Data.Stats.Defense.Level.Value
    local w = nguoiChoi.Data.Stats.Sword.Level.Value
    local x = nguoiChoi.Data.Stats.Gun.Level.Value
    local y = nguoiChoi.Data.Stats.Melee.Level.Value
    local z = nguoiChoi.Data.Stats["Demon Fruit"].Level.Value
    local backpackItemsString = layTenVatPhamTrongBackpack()
    -- Dữ liệu payload cho Discord embed
    local data = {
        ["embeds"] = {
            {
                ["title"] = "📊 Status",
                ["description"] = formattedTime,
                ["color"] = 15258703,
                ["fields"] = {
                    {
                        ["name"] = "Info",
                        ["value"] = "```Beli: " .. a .. ",\nFragments: " .. b .. ",\nSummer Token: " .. c .. ",\nOni Token: " .. d .. ",\nBone : " .. e ..--[[",\nConjured Cocoa: " .. f .. ]] ",\nCelestial Token: " .. g .. "```",
                        ["inline"] = false
                    },
                    {
                        ["name"] = "Backpack",
                        ["value"] = backpackItemsString,
                        ["inline"] = true
                    },
                    {
                        ["name"] = "Stats",
                        ["value"] = "```Defense: " .. v .. ",\nSword: " .. w .. ",\nGun: " .. x .. ",\nMelee: " .. y .. ",\nDemon Fruit: " .. z .. "```",
                        ["inline"] = true
                    } --,
--[[                    
                    {
                        ["name"] = "Other",
                        ["value"] = "Some other information here.",
                        ["inline"] = false
                    }
]]
                },
                ["footer"] = {
                    ["text"] = "Gửi lúc: " .. os.date("%H:%M:%S ngày %d/%m/%Y")
                }
            }
        }
    }

    -- 1. Chuyển đổi bảng Lua thành chuỗi JSON
    local jsonData
    local success, err = pcall(function()
        jsonData = HttpService:JSONEncode(data)
    end)
    
    if not success then
        warn("Lỗi khi mã hóa JSON: ", err)
        return
    end

    -- 2. Gửi yêu cầu HTTP POST với dữ liệu JSON
    local success, response = pcall(function()
        HttpService:RequestAsync({
            Url = webhookURL,
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json"
            },
            Body = jsonData
        })
    end)
    
    if success then
        print("Đã gửi thông báo webhook thành công!")
    else
        warn("Gửi webhook thất bại: ", response)
    end
end

-- Vòng lặp để gửi thông báo định kỳ
while true do
    sendToDiscord()
    wait(_G.Time)
end
