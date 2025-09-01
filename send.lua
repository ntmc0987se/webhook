--[[ 
_G.WebhookURL = "" 
_G.Time = 300
]]
local HttpService = game:GetService("HttpService")

local webhookURL = _G.WebhookURL
local players = game:GetService("Players")
local replicatedStorage = game:GetService("ReplicatedStorage")
local nguoiChoi = players.LocalPlayer

-- Hàm lấy số lượng vật phẩm, đã sửa lại cách duyệt kho đồ
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

-- Hàm gửi tin nhắn tới Discord
local function sendToDiscord()
    -- Lấy dữ liệu từ game
    local uiText1 = nguoiChoi.PlayerGui.Main.Beli.Text
    local uiText2 = nguoiChoi.PlayerGui.Main.Fragments.Text
    local uiText3 = tostring(laySoLuongVatPham("Summer Token"))
    local uiText4 = tostring(laySoLuongVatPham("Oni Token"))

    -- Dữ liệu payload cho Discord embed
    local data = {
        ["embeds"] = {
            {
                ["title"] = "📊 Status",
                ["description"] = "Thông tin tài nguyên của người chơi.",
                ["color"] = 15258703,
                ["fields"] = {
                    {
                        ["name"] = "Beli",
                        ["value"] = uiText1,
                        ["inline"] = true
                    },
                    {
                        ["name"] = "Fragments",
                        ["value"] = uiText2,
                        ["inline"] = true
                    },
                    {
                        ["name"] = "Summer Token",
                        ["value"] = uiText3,
                        ["inline"] = true
                    },
                    {
                        ["name"] = "Oni Token",
                        ["value"] = uiText4,
                        ["inline"] = true
                    }
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
    -- Gọi hàm để gửi thông tin
    sendToDiscord()
    wait(_G.Time)
end

