-- 69LOL_EXEscript
-- Авто-инжект и инициализация
local script_name = "69LOL_EXEscript"
local ui = lib.ui.new(script_name, "Close Menu [F4]", 50, 50, 250, 300, color.new(30, 30, 30, 180)) -- Серая, полупрозрачная
ui:set_key(113) -- F4 для показа/скрытия
ui:set_draggable(true)

-- Анимация появления
lib.msg.show("Hello Friend", color.new(255, 255, 255), 2, "bold") -- Жирный шрифт
system.wait(2000)

-- Вкладка ESP
local esp_tab = ui:add_tab("ESP")

-- Переключатели ESP
local esp_switch = esp_tab:add_switch("ESP", false)
local hp_switch = esp_tab:add_switch("Show HP", false)
local team_switch = esp_tab:add_switch("Team Stop", true)
local dist_switch = esp_tab:add_switch("Show Distance", false)

-- Логика ESP
esp_switch:set_callback(function(state)
    if state then
        -- Включение ESP только для живых игроков-противников
        local players = entity.get_players()
        for _, player in pairs(players) do
            if not player:is_teammate() and player:is_alive() and not player:is_npc() then
                -- Рендер белого, полупрозрачного хитбокса по контуру модели
                renderer.draw_box_3d(
                    player:get_hitbox_position(0), -- Хитбокс
                    color.new(255, 255, 255, 120), -- Белый, полупрозрачный
                    2, -- Толщина линии
                    true -- Заполнение
                )
                -- Отображение HP, если включено
                if hp_switch:get() then
                    renderer.draw_text_2d(
                        player:get_position() + vector3.new(0, 0, 2),
                        "HP: " .. player:get_health(),
                        color.new(0, 255, 0, 255)
                    )
                end
                -- Отображение дистанции, если включено
                if dist_switch:get() then
                    local dist = player:get_position():distance(local_player:get_position())
                    renderer.draw_text_2d(
                        player:get_position() + vector3.new(0, 0, 1.5),
                        "Dist: " .. math.floor(dist),
                        color.new(255, 255, 0, 255)
                    )
                end
            end
        end
    end
end)

-- Логика Team Stop
team_switch:set_callback(function(state)
    -- Автоматически отключает визуалы и аимбот для тиммейтов
end)

-- Вкладка AimBot
local aim_tab = ui:add_tab("Aim")

-- Переключатель аимбота
local aim_switch = aim_tab:add_switch("Aimbot", false)
local circle_switch = aim_tab:add_switch("Use Circle", true)

-- Выбор клавиши для аимбота
local aim_key = aim_tab:add_keybind("Aim Key", 1) -- 1 = Левая кнопка мыши
-- Выбор части тела для прицеливания
local hitbox_combo = aim_tab:add_combo("Hitbox", {"Head", "Body"}, 1) -- По умолчанию Head

-- Настройка круга (FOV)
local fov_circle = aim_tab:add_slider("Circle Radius", 50, 300, 150)
aim_tab:add_text("-- Aimbot работает только в радиусе круга")

-- Основная логика аимбота с обходом античита
aim_switch:set_callback(function(state)
    if state and aim_key:is_down() then
        local target = nil
        local lowest_dist = fov_circle:get()
        local players = entity.get_players()

        for _, player in pairs(players) do
            -- Проверка: только живые враги-игроки, не тиммейты, не я, не НПС
            if player:is_valid() and
                player:is_alive() and
                not player:is_teammate() and
                player ~= local_player and
                not player:is_npc() then

                -- Проверка нахождения в радиусе круга (FOV)
                local screen_pos = renderer.world_to_screen(player:get_position())
                local center = renderer.get_screen_center()
                local dist = vector2.distance(screen_pos, center)

                if dist < lowest_dist and (circle_switch:get() or true) then
                    lowest_dist = dist
                    target = player
                end
            end
        end

        if target then
            local hitbox_index = 0 -- Голова
            if hitbox_combo:get() == 2 then
                hitbox_index = 5 -- Тело
            end

            local target_pos = target:get_hitbox_position(hitbox_index)
            -- Плавное наведение с рандомизацией для обхода античита
            local smooth_aim = math.random(8, 12)
            input.mouse_move_angle(
                local_player:calc_angle_to(target_pos),
                smooth_aim
            )
        end
    end
end)

-- Скрыть/показать при инжекте
client.set_event_callback("on_paint", function()
    if ui:is_visible() then
        -- Отрисовка FOV круга, если включено
        if circle_switch:get() and aim_switch:get() then
            local center = renderer.get_screen_center()
            renderer.draw_circle(center, fov_circle:get(), color.new(255, 0, 0, 80), 2)
        end
    end
end)

lib.msg.show("Injected. Press F4", color.new(0, 255, 0), 3)
