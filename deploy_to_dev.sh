echo "------ run GITHUB_JOB ${GITHUB_JOB} ------"

echo "ALIAS_GITHUB_REPOSITORY: ${ALIAS_GITHUB_REPOSITORY}"
APP_CHART_NAME=`echo ${ALIAS_GITHUB_REPOSITORY} | awk -F "/" '{print $2}'`
echo "APP_CHART_NAME: ${APP_CHART_NAME}"

echo "SECOND_MODULE is ${SECOND_MODULE}"
echo "THIRD_MODULE is ${THIRD_MODULE}"

cd env-dev/${APP_CHART_NAME}
if [ $? != 0 ]; then
    echo "err, no such directory env-dev/${APP_CHART_NAME} "
    exit 1
fi

if [ "$SECOND_MODULE" == "ignore" ] ;then
echo "------  Reserved the image for ${SECOND_MODULE_FOR_COMMON} due to SECOND_MODULE='ingore'------"
COMMON_FOR_SECOND_MODULE=`echo ${SECOND_MODULE_FOR_COMMON} | awk  '{print $1}'`
echo "------ Name of the image.repo to be reserved:  `yq r values.yaml ${COMMON_FOR_SECOND_MODULE}.image.repository`"
echo "------ Name of the image.tag to be reserved:   `yq r values.yaml ${COMMON_FOR_SECOND_MODULE}.image.tag`"
TAG_FOR_SECOND_MODULE=`yq r values.yaml ${COMMON_FOR_SECOND_MODULE}.image.tag`
fi

if [ "$THIRD_MODULE" == "ignore" ] ;then
echo "------ Reserved image for ${THIRD_MODULE_FOR_COMMON} due to THIRD_MODULE=ingore   ------"
COMMON_FOR_THIRD_MODULE=`echo ${THIRD_MODULE_FOR_COMMON} | awk  '{print $1}'`
echo "------ Name of the image.repo to be reserved:  `yq r values.yaml ${COMMON_FOR_THIRD_MODULE}.image.repository`"
echo "------ Name of the image.tag to be reserved:   `yq r values.yaml ${COMMON_FOR_THIRD_MODULE}.image.tag`"
TAG_FOR_THIRD_MODULE=`yq r values.yaml ${COMMON_FOR_THIRD_MODULE}.image.tag`
fi

echo "------ list current common*.image.tag ------"
yq r --printMode pv values.yaml "common*.image.tag"
echo "------ replace common*.image.tag to ${GITHUB_SHA:0:8} ------"
yq w -i values.yaml "common*.image.tag" ${GITHUB_SHA:0:8}
yq r --printMode pv values.yaml "common*.image.tag"

if [ "$SECOND_MODULE" == "ignore" ];
then
  echo "------ rollback the SECOND_MODULE ------"
  for w in `echo ${SECOND_MODULE_FOR_COMMON}`;
  do yq w -i values.yaml ${w}.image.tag ${TAG_FOR_SECOND_MODULE} && yq r values.yaml ${w}.image.tag;
  done
fi

if [ "$THIRD_MODULE" == "ignore" ];
then
  echo "------ rollback the THIRD_MODULE ------"
  for w in `echo ${THIRD_MODULE_FOR_COMMON}`;
  do yq w -i values.yaml ${w}.image.tag ${TAG_FOR_THIRD_MODULE} && yq r values.yaml ${w}.image.tag;
  done
fi

echo "------ list latest common*.image.tag ------"
yq r --printMode pv values.yaml "common*.image.tag"

echo "push the latest SHA: ${GITHUB_SHA:0:8} to the manifest repo ${ALIAS_GITHUB_REPOSITORY}"
git config user.name ${GITHUB_ACTOR}
git config user.email ${GITHUB_ACTOR}@github.com
git diff
git add ./
git commit -m "${GITHUB_REPOSITORY}_${GITHUB_JOB}_${GITHUB_SHA:0:8}_details:${CI_COMMIT_MESSAGE}"
git push
echo -e "======================= \n\n you can check your application status with 'user/passwd:readonly/Te****g' at \n\n \033[31m https://g-argocd.fluxble.com/applications/${APP_CHART_NAME}\033[0m \n\n======================="