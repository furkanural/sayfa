defmodule Sayfa.DateFormatTest do
  use ExUnit.Case, async: false

  alias Sayfa.DateFormat
  alias Sayfa.I18n

  setup do
    I18n.clear_cache()
    :ok
  end

  describe "format/3" do
    test "formats date in English by default" do
      assert "Jan 15, 2024" == DateFormat.format(~D[2024-01-15], :en)
    end

    test "formats date in Turkish" do
      assert "15 Şubat 2024" == DateFormat.format(~D[2024-02-15], :tr)
    end

    test "formats date in German" do
      assert "15. März 2024" == DateFormat.format(~D[2024-03-15], :de)
    end

    test "formats date in French" do
      assert "15 janvier 2024" == DateFormat.format(~D[2024-01-15], :fr)
    end

    test "formats date in Japanese" do
      assert "2024年1月15日" == DateFormat.format(~D[2024-01-15], :ja)
    end

    test "formats date in Spanish" do
      assert "15 de junio de 2024" == DateFormat.format(~D[2024-06-15], :es)
    end

    test "uses per-language config override for date format" do
      config = %{
        default_lang: :en,
        languages: [en: [name: "English", date_format: "%Y-%m-%d"]]
      }

      assert "2024-01-15" == DateFormat.format(~D[2024-01-15], :en, config)
    end

    test "falls back to default format for unknown language" do
      assert DateFormat.format(~D[2024-06-15], :xx) =~ "2024"
    end

    test "handles all 12 months in English" do
      for month <- 1..12 do
        date = Date.new!(2024, month, 1)
        result = DateFormat.format(date, :en)
        assert is_binary(result)
        assert result =~ "2024"
      end
    end

    test "handles all 12 months in Turkish" do
      expected_months = [
        "Ocak",
        "Şubat",
        "Mart",
        "Nisan",
        "Mayıs",
        "Haziran",
        "Temmuz",
        "Ağustos",
        "Eylül",
        "Ekim",
        "Kasım",
        "Aralık"
      ]

      for {month_name, month_num} <- Enum.with_index(expected_months, 1) do
        date = Date.new!(2024, month_num, 15)
        result = DateFormat.format(date, :tr)
        assert result =~ month_name, "Expected #{month_name} in: #{result}"
      end
    end
  end
end
