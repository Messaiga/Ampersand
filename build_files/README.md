# build_files

Scripts that run **inside the image build** (anything that needs a command, like installing a package).
Files that only need to *exist* in the image go in `system_files/` instead.

`build.sh` copies `system_files/` into the image, then runs every `NN-name.sh` here in numeric order.
`IMAGE_NAME` (`ampersand` or `ampersand-dx`) is available to every step, so a step can do DX-only work:

```bash
if [[ "${IMAGE_NAME}" == "ampersand-dx" ]]; then
    ...
fi
```
