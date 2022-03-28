
classdef Unitizer < handle
    properties
        x_pitch
        y_pitch
        x_pitch_inv
        y_pitch_inv
    end

    methods
        function un = Unitizer(x_pitch, y_pitch)
            un.x_pitch = x_pitch;
            un.y_pitch = y_pitch;
            un.x_pitch_inv = 1 / x_pitch;
            un.y_pitch_inv = 1 / y_pitch;
        end

        function px = x_mm2px(un, mm)
            px = un.x_pitch_inv * mm;
        end

        function px = y_mm2px(un, mm)
            px = un.y_pitch_inv * mm;
        end

        function px = mm2px(un, mm)
            px = [un.x_pitch_inv un.y_pitch_inv] .* mm;
        end

        function mm = x_px2mm(un, px)
            mm = un.x_pitch * px;
        end

        function mm = y_px2mm(un, px)
            mm = un.y_pitch * px;
        end

        function mm = px2mm(un, px)
            mm = [un.x_pitch un.y_pitch] .* px;
        end
    end
end