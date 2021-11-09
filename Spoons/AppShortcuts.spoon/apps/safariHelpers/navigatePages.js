var pattern =
  direction == "next"
    ? ">|next|forward|older|continue"
    : "newer|back|prev(ious)?|<";
document.querySelectorAll("a").forEach((element) => {
  var text = element.text;
  var className = element.className;
  var after = getComputedStyle(element, ":after").content;
  var before = getComputedStyle(element, ":before").content;
  var re = new RegExp(pattern, "i");
  var match = [text, className, after, before].find((p) => re.test(p));
  if (match) {
    element.click();
    return;
  }
});
