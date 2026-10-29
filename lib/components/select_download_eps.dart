import 'package:flutter/material.dart';
import 'package:flutter_miuix/miuix.dart';
import 'package:pica_comic/tools/translations.dart';

class SelectDownloadChapter extends StatefulWidget {
  const SelectDownloadChapter(this.eps, this.finishSelect, this.downloadedEps,
      {Key? key})
      : super(key: key);
  final List<String> eps;
  final void Function(List<int>) finishSelect;
  final List<int> downloadedEps;

  @override
  State<SelectDownloadChapter> createState() => _SelectDownloadChapterState();
}

class _SelectDownloadChapterState extends State<SelectDownloadChapter> {
  List<int> selected = [];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 16, 0, 16),
            child: Text(
              "下载漫画".tl,
              style: const TextStyle(fontSize: 22),
            ),
          ),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 300,
                childAspectRatio: 4,
              ),
              itemBuilder: (BuildContext context, int i) {
                return Padding(
                  padding: const EdgeInsets.all(4),
                  child: MiuixPressable(
                      borderRadius: const BorderRadius.all(Radius.circular(16)),
                      onPressed: widget.downloadedEps.contains(i)
                          ? null
                          : () {
                              setState(() {
                                if (selected.contains(i)) {
                                  selected.remove(i);
                                } else {
                                  selected.add(i);
                                }
                              });
                            },
                      child: AnimatedContainer(
                        decoration: BoxDecoration(
                          borderRadius:
                              const BorderRadius.all(Radius.circular(16)),
                          color: (selected.contains(i) ||
                                  widget.downloadedEps.contains(i))
                              ? Theme.of(context).colorScheme.primaryContainer
                              : Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest,
                        ),
                        duration: const Duration(milliseconds: 200),
                        child: Row(
                          children: [
                            const SizedBox(
                              width: 16,
                            ),
                            Expanded(
                              child: Text(
                                widget.eps[i],
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (selected.contains(i)) const Icon(Icons.done),
                            if (widget.downloadedEps.contains(i))
                              const Icon(Icons.download_done),
                            const SizedBox(
                              width: 16,
                            ),
                          ],
                        ),
                      )),
                );
              },
              itemCount: widget.eps.length,
            ),
          ),
          const SizedBox(height: 14),
          Builder(builder: (context) {
            final scheme = Theme.of(context).colorScheme;
            final selectable = <int>[
              for (int i = 0; i < widget.eps.length; i++)
                if (!widget.downloadedEps.contains(i)) i
            ];
            final allSelected = selectable.isNotEmpty &&
                selectable.every((e) => selected.contains(e));
            final canDownload = selected.isNotEmpty;
            Widget button(String text, Color bg, Color fg, VoidCallback? onTap) {
              return Expanded(
                child: MiuixPressable(
                  borderRadius: const BorderRadius.all(Radius.circular(16)),
                  onPressed: onTap,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: 50,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: bg,
                      borderRadius: const BorderRadius.all(Radius.circular(16)),
                    ),
                    child: Text(
                      text,
                      style: TextStyle(
                          color: fg, fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              );
            }

            return Row(
              children: [
                button(
                  allSelected ? "全不选".tl : "全选".tl,
                  scheme.secondaryContainer,
                  scheme.onSecondaryContainer,
                  selectable.isEmpty
                      ? null
                      : () {
                          setState(() {
                            if (allSelected) {
                              selected.clear();
                            } else {
                              selected = List<int>.from(selectable);
                            }
                          });
                        },
                ),
                const SizedBox(width: 12),
                button(
                  "下载".tl,
                  canDownload
                      ? scheme.primary
                      : scheme.primary.withValues(alpha: 0.38),
                  canDownload
                      ? scheme.onPrimary
                      : scheme.onPrimary.withValues(alpha: 0.7),
                  canDownload
                      ? () {
                          selected.sort();
                          widget.finishSelect(selected);
                        }
                      : null,
                ),
              ],
            );
          }),
          const SizedBox(height: 8),
          SizedBox(
            height: MediaQuery.of(context).padding.bottom + 12,
          )
        ],
      ),
    );
  }
}
