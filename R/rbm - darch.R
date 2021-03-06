# Loading library
if(exists("configs") == F){
	library(darch)
	configs = data.frame(epochs_rbm=integer(), batch_rbm=integer(), ln_rate_rbm=numeric(), ln_scale_rbm=numeric(), cd_rbm=integer(), layers=character(), batch=integer(), ln_rate_bp=numeric(), ln_scale_bp=numeric(), epochs_ft=integer(), classification_error=numeric())
	predict_list <- list()
	predict_norm_list <- list()
	nn_list <- list()
}

#1 = work with onehot vector encoding for the lables
onehot <- 1

# Load csv

X_train <- read.csv(file="../csv/X_train_A.csv", header=T, sep=",", row.names=1)
X_test <- read.csv(file="../csv/X_test_A.csv", header=T, sep=",", row.names=1)
y_train_org <- read.csv(file="../csv/y_train_A.csv", header=T, sep=",", row.names=1)
y_test_org <- read.csv(file="../csv/y_test_A.csv", header=T, sep=",", row.names=1)

X_train <- X_train[2:nrow(X_train),]
X_test <- X_test[2:nrow(X_test),]

# trying one hot encoding
onehot_test <- matrix(0L, nrow=dim(y_test_org)[1], ncol=max(y_test_org)+1)
counter <- 1
for(y in 1:dim(y_test_org)[1]){
	onehot_test[counter,y_test_org[y,]+1] <- 1
	counter <- counter+1
}
# trying one hot encoding
onehot_train <- matrix(0L, nrow=dim(y_train_org)[1], ncol=max(y_train_org)+1)
counter <- 1
for(y in 1:dim(y_train_org)[1]){
	onehot_train[counter, y_train_org[y,]+1] <- 1
	counter <- counter+1
}

X_train <- as.matrix(X_train)
X_test <- as.matrix(X_test)
y_train <- as.matrix(y_train_org)
y_test <- as.matrix(y_test_org)

if(onehot){
	y_test <- onehot_test
	y_train <- onehot_train
}

epochs_rbm <- 10
batch_rbm <- 100
ln_rate_rbm <- .01
ln_scale_rbm <- 1
cd_rbm <- 10
layers <- c(ncol(X_train),100,5)
units <- c(tanhUnit, softmaxUnit)
batch <- 200
ln_rate_bp <- .01
ln_scale_bp <- 1
epochs_ft <- 10
  
# only take 1000 samples, otherwise training takes increasingly long
#chosenRowsTrain <- sample(1:nrow(trainData), size=nrow(X_train))
#trainDataSmall <- trainData[chosenRowsTrain,]
#trainLabelsSmall <- trainLabels[chosenRowsTrain,]
  
darch  <- darch(X_train, y_train,
  rbm.numEpochs = epochs_rbm,
  rbm.consecutive = F, # each RBM is trained one epoch at a time
  rbm.batchSize = batch_rbm,
  rbm.lastLayer = -1, # don't train output layer
  rbm.allData = T, # use bootstrap validation data as well for training
  rbm.errorFunction = rmseError,
  rbm.initialMomentum = .5,
  rbm.finalMomentum = .7,
  rbm.learnRate = ln_rate_rbm,
  rbm.learnRateScale = ln_scale_rbm,
  rbm.momentumRampLength = .8,
  rbm.numCD = cd_rbm,
  rbm.unitFunction = sigmoidUnitRbm,
  rbm.weightDecay = .001,
  layers = layers,
  darch.batchSize = batch,
  darch.dither = T,
  darch.initialMomentum = .4,
  darch.finalMomentum = .9,
  darch.momentumRampLength = .75,
  bp.learnRate = ln_rate_bp,
  bp.learnRateScale = ln_scale_bp,
  darch.unitFunction = units,
  bootstrap = T,
  darch.numEpochs = epochs_ft,
  gputools = T, # try to use gputools
  gputools.deviceId = 0,
  xValid = X_test,
  yValid = y_test
)

predictions <- predict(darch, newdata=X_test, type="class")
  
labels <- cbind(predictions, y_test)
numIncorrect <- sum(apply(labels, 1, function(i) { any(i[1:5] != i[6:10]) }))
cat(paste0("Incorrect classifications on test data: ", numIncorrect," (", round(numIncorrect/nrow(y_test)*100, 2), "%)\n"))
 
configs <- rbind(configs,data.frame(epochs_rbm= epochs_rbm, batch_rbm= batch_rbm, ln_rate_rbm= ln_rate_rbm, ln_scale_rbm= ln_scale_rbm, cd_rbm= cd_rbm, layers= paste(layers,collapse=" "), batch= batch, ln_rate_bp= ln_rate_bp, ln_scale_bp= ln_scale_bp, epochs_ft= epochs_ft, classification_error=numIncorrect/nrow(y_test)))
predict_list[[dim(configs)[1]]] <- predictions
predict_norm_list[[dim(configs)[1]]] <- labels
nn_list[[dim(configs)[1]]] <- darch

darch
configs
