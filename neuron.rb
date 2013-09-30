# encoding: utf-8
require "wx"
require 'RMagick'

include Wx
include Magick


# TODO new todo
# wxWindow frame
class RecognizeFrame < Wx::Frame
  def initialize
    @model = Model.new(10, 64 * 64)

    super(nil,  :title => "Распознавание цифр", 
                :pos => DEFAULT_POSITION, 
                :size => [230, 92],
                :style => CAPTION | CLOSE_BOX | CLIP_CHILDREN)
    panel = Wx::Panel.new(self)

    files = Dir['images/*.jpg']
    countfiles = files.size

    # todo teach button fix
    # teach button
    label = Wx::StaticText.new(panel, :label => "Всего #{countfiles} файлов", :pos => [15, 16])
    teach_bt = Wx::Button.new(panel, :label => 'Учить', :pos => [135, 10])
    evt_button(teach_bt) { teach }

    # todo: field for text fix
    # field for text
    search_bt = Wx::Button.new(panel, :label => 'Распознать из файла', :pos => [10, 50], :size => [210, 28])
    @fd = Wx::FileDialog.new(panel, :label => 'Выберите изображение')
    evt_button(search_bt) { recognize }

    show
  end

  # teach model
  # todo: model fix
  def teach 
    t = Teacher.new(@model) # todo must be deprecated **(as soon as possible)**
    t.teach  
  end

  # recognize
  # FIXME: improve recognizer
  def recognize
    if @fd.show_modal == Wx::ID_OK
      # load file  
      file = Magick::ImageList.new(@fd.filename)
      x = Array.new
      file.each_pixel do |pixel, c, r|
        if (pixel.red > 50000) 
          x.push(0)
        else
          x.push(1)
        end
      end 

      # try to recognize
      val = get_digit(@model.recognize(x)) 
      diag = Wx::MessageDialog.new(nil, :message => "Результат: #{val}", :caption => "Распознавание", :style => Wx::OK)
      diag.show_modal
    end
  end

  private
  def get_digit(y)
    x = 0
    y.each_index do |i|
      x = i if y[i] == 1    
    end
    return x
  end
end


# wxWindow app
class RecognizeApp < App
  def on_init
    RecognizeFrame.new
  end
end


# neuron class - basic structure
class Neuron
  # class constructor
  def initialize(n)
    @w = Array.new(n) 
  end

  # transfer function
  def transfer(x)
    return activator(adder(x))  
  end

  # random values for each synapse
  def initWeights(n)
    @w.each_index { |i| @w[i] = Random.rand(n) }  
  end

  # modificate synapse weights
  def changeWeights(d, x)
    @w.each_index { |i| @w[i] += d * x[i] }  
  end

  # summator
  def adder(x)
    nec = 0
    x.each_index { |i| nec += x[i] * @w[i] }
    return nec
  end

  # activation function
  def activator(nec)
	k = 0.5
	a = 100 / (1 + Math.exp(-k * nec))
	
	return Float(a.floor) / 100
  end

  private :adder, :activator
end


# model - class for storing 10 neuron objects
class Model
  # class constructor
  def initialize(n, m)
    @n = n
    @m = m
    @neurons = Array.new(n)
    @neurons.each_index { |i| @neurons[i] = Neuron.new(m) }
  end

  # recognition function
  def recognize(x)
    y = Array.new(@neurons.length)
    @neurons.each_index { |i| y[i] = @neurons[i].transfer(x) }
    return y
  end

  # random values for each neuron
  def initWeights
    @neurons.each_index { |i| @neurons[i].initWeights(10) }  
  end

  # teach function
  def teach(x, y)
    t = recognize(x)
    while not equal(t, y) do
      @neurons.each_index do |i|
        d = y[i] - t[i]
        @neurons[i].changeWeights(d, x)      
      end
      t = recognize(x)
    end
  end

  # check for two vectors equality
  def equal(a, b)
    return false if a.length != b.length
    a.each_index do |i|
      return false if a[i] != b[i]    
    end
    return true
  end

  private :equal
  attr_reader :n, :m
end


# teaching class
class Teacher
  # class constructor
  def initialize(model)
    @model = model  
  end

  # main teaching function
  def teach
    # get images to images array
    images = Array.new
    files = Dir['images/*.jpg']
    files.each do |f|
      images.push(Magick::ImageList.new(f))
    end  
    n = files.length

    # init weights
    @model.initWeights
    
    # get pixel arrays for each image
    while n > 0 do
      n = n - 1
      images.each_index do |im|
        w = images[im].columns
        h = images[im].rows
        
        next if w * h > @model.m

        # x is vector from 0 and 1
        x = Array.new
        images[im].each_pixel do |pixel, c, r|
          if (pixel.red > 50000) 
            x.push(0)
          else
            x.push(1)
          end
        end 
      
        # out vector
        y = Array.new(@model.n)
        y.each_index do |i|
          if i == Integer(files[im][7])
            y[i] = 1
          else
            y[i] = 0
          end        
        end

        @model.teach(x, y)
      end  

      t = files.length - n
      print "#{t} "  
    end
  end
end


# run app
RecognizeApp.new.main_loop




