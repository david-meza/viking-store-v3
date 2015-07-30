require "rails_helper"


describe Order do

  context "#value" do
    it 'should properly calculate the value' do
      expect(Order.first.value).to eq(1862.56)
    end
  end

  context ".in_last" do
    it 'should properly count all orders if no argument passed' do
      expect(Order.in_last).to eq(300)
    end

    it 'should properly count the right number of orders (7 days)' do
      expect(Order.in_last(7)).to eq(8)
    end

    it 'should properly count the right number of orders (30 days)' do
      expect(Order.in_last(30)).to eq(29)
    end
  end

  context ".average_in_last" do
    it 'should properly average the orders of all time' do
      expect(Order.average_in_last).to be_within(0.1).of(1406.70)
    end

    it 'should properly average the orders in the last 30 days' do
      expect(Order.average_in_last(30)).to be_within(0.1).of(1403.71)
    end

    it 'should properly average the orders in the last 7 days' do
      expect(Order.average_in_last(7)).to be_within(0.1).of(1458.32)
    end
  end

  context ".largest_in_last" do
    it "should return the highest single order value of all time" do
      expect(Order.largest_in_last).to be_within(0.1).of(5758.67)
    end
    it "should return the highest single order value (7 days)" do
      expect(Order.largest_in_last(7)).to be_within(0.1).of(2678.73)
    end
  end

  context ".revenue_in_last" do
    it "should return the earned revenue of all time" do
      expect(Order.revenue_in_last(nil)).to be_within(0.1).of(446736.33)
    end
    it "should return the earned revenue (7 days)" do
      expect(Order.revenue_in_last(7)).to be_within(0.1).of(11666.55)
    end
  end
end
