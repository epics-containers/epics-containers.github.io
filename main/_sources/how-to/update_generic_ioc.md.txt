# Updating a Generic IOC to the Latest Copier Template

This requires that you have copier in your path which you can do by activating a virtual environment and installing it.

```bash
python3 -m venv venv
source venv/bin/activate
pip install copier
```

Then you can run the following commands to update your generic IOC to the latest template, this example for ioc-adaravis.

```bash
git clone git@github.com:epics-containers/ioc-adaravis --recursive
cd ioc-adaravis
git checkout -b update-template
copier update --trust
cd ibek-support
checkout main
cd ..
git add .
git commit -m "Update to latest template"
git push -u origin update-template
```

Now check the CI runs as expected. You may also verify locally with:

```bash
./build.sh
./tests/run_tests.sh
```
