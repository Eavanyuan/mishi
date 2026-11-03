package handler

import "testing"

func TestToStringSlice_CompatibleFormats(t *testing.T) {
	t.Run("plain string array", func(t *testing.T) {
		raw := []byte(`["a","b"]`)
		got := toStringSlice(raw)
		if len(got) != 2 || got[0] != "a" || got[1] != "b" {
			t.Fatalf("unexpected result: %#v", got)
		}
	})

	t.Run("object array with text field", func(t *testing.T) {
		raw := []byte(`[{"text":"故人西辞黄鹤楼"},{"text":"烟花三月下扬州"}]`)
		got := toStringSlice(raw)
		if len(got) != 2 || got[0] != "故人西辞黄鹤楼" || got[1] != "烟花三月下扬州" {
			t.Fatalf("unexpected result: %#v", got)
		}
	})

	t.Run("single object fallback", func(t *testing.T) {
		raw := []byte(`{"text":"单句"}`)
		got := toStringSlice(raw)
		if len(got) != 1 || got[0] != "单句" {
			t.Fatalf("unexpected result: %#v", got)
		}
	})
}

