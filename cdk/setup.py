import setuptools


with open("README.md") as fp:
    long_description = fp.read()


setuptools.setup(
    name="aws_synctags",
    version="0.0.1",

    description="Keep dependent resource tags in sync.",
    long_description=long_description,
    long_description_content_type="text/markdown",

    author="https://github.com/lairdnet/aws-synctags",

    package_dir={"": "aws_synctags"},
    packages=setuptools.find_packages(where="aws_synctags"),

    install_requires=[
        "aws-cdk.core",
        "aws-cdk.aws-events",
        "aws-cdk.aws-events-targets",
        "aws-cdk.aws-lambda",
        "aws-cdk.aws-iam",
        "aws-cdk.aws-sns"
    ],

    python_requires=">=3.6",

    classifiers=[
        "Development Status :: 4 - Beta",

        "Intended Audience :: Developers",

        "License :: OSI Approved :: Apache Software License",

        "Programming Language :: Python :: 3.6",
        "Programming Language :: Python :: 3.7",
        "Programming Language :: Python :: 3.8",
    ],
)
