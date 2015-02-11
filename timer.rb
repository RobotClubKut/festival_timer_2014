#!/usr/bin/ruby
# -*- coding: utf-8 -*-

# 学祭用タイマー 2014
# for Ruby 1.9.3 (and Ocra)
# (C) 2011-2012, 2014 水音氷音.

if ENV.key?("OCRA_EXECUTABLE")
	relative_path = File.expand_path(File.dirname(__FILE__))
else
	relative_path = '.'
end

SETTING_FILE = '.\setting.ini'

require 'starruby'
require (relative_path + '/inifiles').encode('SJIS')

include StarRuby

exit if (defined?(Ocra))

# ===================================================================

MB_OK = 0

def MessageBox(wnd, text, caption, type = MB_OK)
	messagebox = Win32API.new('user32', 'MessageBox', %w(p p p i), 'i')
	messagebox.call(wnd, text.encode('SJIS'), caption.encode('SJIS'), type)
end

# ===================================================================

class Float
	def to_time_str
		sprintf("%02d:%02d' %02d''", floor / 60, floor % 60, (self * 100).floor % 100)
	end
end

class Factory
	def initialize
		@data = {}
	end
	
	def get(*args)
		if @data[args]
			@data[args]
		else
			@data[args] = type.new(*args)
		end
	end
end

class FontFactory < Factory
	def type
		Font
	end
end

class ColorFactory < Factory
	def type
		Color
	end
end

class Timer
	def initialize
		clear
		@limit = 0.0
	end
	
	def clear
		@start_time = nil
		@stop_time  = nil
	end
	
	def start
		@start_time = Time.now
		@stop_time  = nil
	end
	
	def start?
		!!@start_time
	end
	
	def stop
		@stop_time = Time.now unless stop?
	end
	
	def stop?
		!!@stop_time
	end
	
	def to_f
		val = 0.0
		
		if start?
			if stop?
				val = @stop_time - @start_time
			else
				val = Time.now - @start_time
			end
		end
		
		if val > @limit
			stop
			@limit.to_f
		else
			val
		end
	end
	
	def to_s
		to_f.to_time_str
	end
	
	attr_accessor :limit
end

# ===================================================================

class TimerConfig
	Fonts   = [ 'title', 'remaining_time', 'remaining', 'remaining2', 'elapsed_time' ]
	Strings = [ 'title', 'remaining', 'remaining2', 'elapsed' ]
	Colors  = [ 'title', 'remaining_time', 'remaining', 'remaining2', 'elapsed', 'elapsed_time' ]
	Margins = [ 'title', 'elapsed_time' ]
	
	def initialize(filename)
		@inifile = Inifile.new(filename)
		reload
	end
	
	def reload
		@gui_fullscreen = @inifile.ReadString('gui', 'fullscreen') == 'true'
		@gui_fps        = @inifile.ReadString('gui', 'fps').to_i
		@gui_width      = @inifile.ReadString('gui', 'width').to_i
		@gui_height     = @inifile.ReadString('gui', 'height').to_i
		
		@time_limit   = @inifile.ReadString('time', 'limit').to_i
		@time_reverse = @inifile.ReadString('time', 'reverse') == 'true'
		
		Fonts.each do |font|
			temp = @inifile.ReadString('font', font).split(',')
			instance_variable_set("@font_#{font}", [temp.first, temp.last.to_i])
		end
		
		Strings.each do |string|
			instance_variable_set(
				"@string_#{string}",
				@inifile.ReadString('string', string.to_s)
				)
		end
		
		Colors.each do |val|
			instance_variable_set(
				"@color_#{val}",
				@inifile.ReadString('color', val).split(',').map {|i| i.to_i }
				)
		end
		
		Margins.each do |val|
			instance_variable_set(
				"@margin_#{val}",
				@inifile.ReadString('margin', val).split(',').map {|i| i.to_i }
				)
		end
	end
	
	attr_reader :gui_fullscreen, :gui_fps, :gui_width, :gui_height
	attr_reader :time_limit, :time_reverse
	attr_reader *(Fonts.map{|i| "font_#{i}" })
	attr_reader *(Strings.map{|i| "string_#{i}" })
	attr_reader *(Colors.map{|i| "color_#{i}" })
	attr_reader *(Margins.map{|i| "margin_#{i}" })
	
	attr_writer :gui_fullscreen
	attr_writer :time_reverse
end

# ===================================================================

unless FileTest.file?(SETTING_FILE)
	MessageBox(0, '設定ファイルが読み込めません。', '起動エラー')
	exit
end

timer  = Timer.new
font   = FontFactory.new
color  = ColorFactory.new
config = TimerConfig.new(SETTING_FILE)

# 座標を計算する
title_size = font.get(*config.font_title).get_size(config.string_title)
title_x    = config.margin_title.last
title_y    = config.margin_title.first

remaining_time_size = font.get(*config.font_remaining_time).get_size((0.0).to_time_str)
remaining_time_x    = config.gui_width  / 2 - remaining_time_size.first / 2
remaining_time_y    = config.gui_height / 2 - remaining_time_size.last  / 2

remaining_size = font.get(*config.font_remaining).get_size(config.string_remaining)
remaining_x    = remaining_time_x
remaining_y    = remaining_time_y - remaining_size.last

remaining2_size = font.get(*config.font_remaining2).get_size(config.string_remaining2)
remaining2_x    = remaining_time_x
remaining2_y    = remaining_time_y + remaining_time_size.last

elapsed_time_size = font.get(*config.font_elapsed_time).get_size((0.0).to_time_str)
elapsed_time_x    = config.gui_width  - elapsed_time_size.first - config.margin_elapsed_time.last
elapsed_time_y    = config.gui_height - elapsed_time_size.last  - config.margin_elapsed_time.first

# ===================================================================

Game.run(
	config.gui_width, config.gui_height,
		:fps        => config.gui_fps,
		:fullscreen => config.gui_fullscreen,
		:title      => config.string_title
) do |game|
	# キーボードの入力を取得
	keyboard = Input.keys(:keyboard, :duration => 1)
	
	# Escape キーで終了
	break if keyboard.include?(:escape)
	
	# F11 キーでウィンドウモードとフルスクリーンの切り替え
	if Input.keys(:keyboard, :duration => 1).include?(:f11)
		config.gui_fullscreen = !config.gui_fullscreen
	end
	
	unless game.fullscreen? == config.gui_fullscreen
		game.fullscreen = config.gui_fullscreen
	end
	
	# F5 キーで設定リロード
	if Input.keys(:keyboard, :duration => 1).include?(:f5)
		config.reload
	end
	
	# 経過時間と残り時間を反転表記
	if Input.keys(:keyboard, :duration => 1).include?(:r)
		config.time_reverse = !config.time_reverse
	end
	
	# Enter キーで開始
	if keyboard.include?(:enter)
		if timer.stop?
			timer.clear
		elsif timer.start?
			timer.stop
		else
			timer.limit = config.time_limit
			timer.start
		end
	end
	
	# 残り時間を計算する
	remaining_time = (config.time_limit - timer.to_f).to_time_str
	
	# 経過時間を求める
	elapsed_time = timer.to_s
	
	# 画面のクリア処理
	game.screen.clear
	
	# テキストを描画
	game.screen.render_text(
		config.string_title,
		title_x,
		title_y,
		font.get(*config.font_title),
		color.get(*config.color_title)
	)
	
	game.screen.render_text(
		config.time_reverse ? elapsed_time : remaining_time,
		remaining_time_x,
		remaining_time_y,
		font.get(*config.font_remaining_time),
		color.get(*config.color_remaining_time)
	)
	
	game.screen.render_text(
		config.time_reverse ? config.string_elapsed : config.string_remaining,
		remaining_x,
		remaining_y,
		font.get(*config.font_remaining),
		color.get(*config.color_remaining)
	)
	
	game.screen.render_text(
		config.string_remaining2,
		remaining2_x,
		remaining2_y,
		font.get(*config.font_remaining2),
		color.get(*config.color_remaining2)
	)
	
	game.screen.render_text(
		config.time_reverse ? remaining_time : elapsed_time,
		elapsed_time_x,
		elapsed_time_y,
		font.get(*config.font_elapsed_time),
		color.get(*config.color_elapsed_time)
	)
end
