local sp = require 'lib.samp.events'
local basexx = require 'basexx'
local sha1 = require 'sha1'

-- Массив IP-адресов серверов и соответствующие им коды Google Authenticator
local servers = {
    {ip = '54.37.142.72', google_code = '', password = ''}, -- Рэд
    {ip = '54.37.142.73', google_code = '', password = ''}, -- Грин
    {ip = '54.37.142.74', google_code = '', password = ''}, -- Блю
    {ip = '51.83.153.240', google_code = '', password = ''} -- Шоко
}

local current_google_code = nil  -- Переменная для хранения кода GA текущего сервера
local current_password = nil  -- Переменная для хранения пароля от аккаунта на текущем сервере

function main()
	if not isSampLoaded() or not isSampfuncsLoaded() then return end
	while not isSampAvailable() do wait(100) end

	local current_server_ip = sampGetCurrentServerAddress()
	local found = false
	
	for _, server in ipairs(servers) do
		if current_server_ip == server.ip then
			current_google_code = server.google_code  -- Устанавливаем код GA для текущего сервера
			current_password = server.password  -- Устанавливаем password для текущего сервера
			found = true
			break
		end
	end

	if not found then
		sampAddChatMessage("Google Authenticator - {00CC00}Вы подключены к неизвестному серверу, скрипт будет выгружен.", 0x3399FF)
		sampAddChatMessage("Google Authenticator - {00CC00}Переподключитесь к известному серверу или добавьте новый сервер в список.", 0x3399FF)
		thisScript():unload()
end
end

function sp.onShowDialog(id, style, title, button1, button2, text)
	if id == 1 then
		sampSendDialogResponse(id, 1, _, current_password)
		return false
	end
	
	if id == 88 and current_google_code then
		local generated_code = google_create(current_google_code)
		sampAddChatMessage("Google Authenticator - {00CC00}��������� ������ ������������ � ������� {FFCC00}- " .. generated_code, 0x3399FF)
		sampSendDialogResponse(id, 1, _, generated_code)
		return false
	end
end

function google_create(skey)
	skey = basexx.from_base32(skey)
	value = math.floor(os.time() / 30)
	value = string.char(0, 0, 0, 0, bit.band(value, 0xFF000000) / 0x1000000, bit.band(value, 0xFF0000) / 0x10000, bit.band(value, 0xFF00) / 0x100, bit.band(value, 0xFF))
	local hash = sha1.hmac_binary(skey, value)
	local offset = bit.band(hash:sub(-1):byte(1, 1), 0xF)
	local function bytesToInt(a,b,c,d) return a*0x1000000 + b*0x10000 + c*0x100 + d end
	hash = bytesToInt(hash:byte(offset + 1, offset + 4))
	hash = bit.band(hash, 0x7FFFFFFF) % 1000000
	return ('%06d'):format(hash)
end
